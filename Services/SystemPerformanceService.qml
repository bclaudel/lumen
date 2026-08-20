pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int historyLimit: 30

    property bool cpuAvailable: false
    property var cpuHistory: []
    property real cpuLoadAverage: 0
    property real cpuTemperature: 0
    property bool cpuTemperatureAvailable: false
    property int cpuThreadCount: 0
    property real cpuUsage: 0

    property bool gpuAvailable: false
    property real gpuClockMhz: 0
    property var gpuHistory: []
    property real gpuMemoryTotalMib: 0
    property real gpuMemoryUsedMib: 0
    property string gpuName: ""
    property real gpuPowerWatts: 0
    property real gpuTemperature: 0
    property real gpuUsage: 0

    property bool memoryAvailable: false
    property var memoryHistory: []
    property real memoryTotalBytes: 0
    property real memoryUsage: 0
    property real memoryUsedBytes: 0
    property real swapTotalBytes: 0
    property real swapUsedBytes: 0

    property real previousCpuIdle: -1
    property real previousCpuTotal: -1

    function appendSample(history, value) {
        const nextHistory = history.slice(Math.max(0, history.length - historyLimit + 1));
        nextHistory.push(value);
        return nextHistory;
    }

    function parseCpuStat(contents) {
        const lines = contents.trim().split("\n");
        if (lines.length === 0)
            return;

        const fields = lines[0].trim().split(/\s+/).slice(1).map(Number);
        if (fields.length < 8 || fields.some(value => !Number.isFinite(value)))
            return;

        const idle = fields[3] + fields[4];
        const total = fields.slice(0, 8).reduce((sum, value) => sum + value, 0);
        cpuThreadCount = lines.filter(line => /^cpu\d+\s/.test(line)).length;

        if (previousCpuTotal >= 0) {
            const totalDelta = total - previousCpuTotal;
            const idleDelta = idle - previousCpuIdle;
            if (totalDelta > 0) {
                cpuUsage = Math.max(0, Math.min(100, 100 * (totalDelta - idleDelta) / totalDelta));
                cpuHistory = appendSample(cpuHistory, cpuUsage);
                cpuAvailable = true;
            }
        }

        previousCpuIdle = idle;
        previousCpuTotal = total;
    }

    function parseGpuLine(line) {
        const fields = line.split(",").map(field => field.trim());
        if (fields.length < 7)
            return;

        const usage = Number(fields[1]);
        const memoryUsed = Number(fields[2]);
        const memoryTotal = Number(fields[3]);
        const temperature = Number(fields[4]);
        const power = Number(fields[5]);
        const clock = Number(fields[6]);
        if (![usage, memoryUsed, memoryTotal, temperature, power, clock].every(Number.isFinite))
            return;

        gpuName = fields[0];
        gpuUsage = Math.max(0, Math.min(100, usage));
        gpuMemoryUsedMib = memoryUsed;
        gpuMemoryTotalMib = memoryTotal;
        gpuTemperature = temperature;
        gpuPowerWatts = power;
        gpuClockMhz = clock;
        gpuHistory = appendSample(gpuHistory, gpuUsage);
        gpuAvailable = true;
    }

    function parseLoadAverage(contents) {
        const value = Number(contents.trim().split(/\s+/)[0]);
        if (Number.isFinite(value))
            cpuLoadAverage = value;
    }

    function parseMemoryInfo(contents) {
        const values = {};
        for (const line of contents.trim().split("\n")) {
            const match = line.match(/^(\w+):\s+(\d+)/);
            if (match)
                values[match[1]] = Number(match[2]) * 1024;
        }

        const total = values.MemTotal ?? 0;
        const available = values.MemAvailable ?? 0;
        if (total <= 0 || available < 0)
            return;

        memoryTotalBytes = total;
        memoryUsedBytes = Math.max(0, total - available);
        memoryUsage = Math.max(0, Math.min(100, 100 * memoryUsedBytes / total));
        swapTotalBytes = values.SwapTotal ?? 0;
        swapUsedBytes = Math.max(0, swapTotalBytes - (values.SwapFree ?? 0));
        memoryHistory = appendSample(memoryHistory, memoryUsage);
        memoryAvailable = true;
    }

    function parseSensors(contents) {
        try {
            const sensors = JSON.parse(contents);
            const preferredDevices = Object.keys(sensors).filter(name => name.startsWith(
                                                                             "k10temp-"));
            const devices = preferredDevices.concat(Object.keys(sensors).filter(name =>
            !name.startsWith("k10temp-")));
            const preferredLabels = ["Tctl", "Tdie", "CPU Package", "CPU"];

            for (const label of preferredLabels) {
                for (const deviceName of devices) {
                    const sensor = sensors[deviceName]?.[label];
                    if (!sensor)
                        continue;
                    const inputName = Object.keys(sensor).find(name => name.endsWith("_input"));
                    const value = Number(sensor[inputName]);
                    if (Number.isFinite(value)) {
                        cpuTemperature = value;
                        cpuTemperatureAvailable = true;
                        return;
                    }
                }
            }
        } catch (error) {
            console.warn("Failed to parse CPU temperature sensors:", error);
        }

        cpuTemperatureAvailable = false;
    }

    function refreshSystemMetrics() {
        cpuStatFile.reload();
        loadAverageFile.reload();
        memoryInfoFile.reload();
    }

    Component.onCompleted: {
        refreshSystemMetrics();
        temperatureQuery.running = true;
    }

    Timer {
        interval: 2000
        repeat: true
        running: true

        onTriggered: root.refreshSystemMetrics()
    }

    Timer {
        interval: 10000
        repeat: true
        running: true

        onTriggered: {
            if (!temperatureQuery.running)
            temperatureQuery.running = true;
        }
    }

    Timer {
        id: gpuRestartTimer

        interval: 5000
        onTriggered: gpuMonitor.running = true
    }

    FileView {
        id: cpuStatFile

        blockLoading: true
        path: "/proc/stat"
        printErrors: false

        onLoaded: root.parseCpuStat(text())
    }

    FileView {
        id: loadAverageFile

        blockLoading: true
        path: "/proc/loadavg"
        printErrors: false

        onLoaded: root.parseLoadAverage(text())
    }

    FileView {
        id: memoryInfoFile

        blockLoading: true
        path: "/proc/meminfo"
        printErrors: false

        onLoaded: root.parseMemoryInfo(text())
    }

    Process {
        id: temperatureQuery

        command: ["sensors", "-j"]

        stdout: StdioCollector {
            onStreamFinished: root.parseSensors(text)
        }
    }

    Process {
        id: gpuMonitor

        property bool startedOnce: false

        command: ["nvidia-smi",
            "--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,clocks.current.graphics",
            "--format=csv,noheader,nounits", "--loop-ms=2000"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => root.parseGpuLine(line)
        }

        onRunningChanged: {
            if (running) {
                startedOnce = true;
            } else if (startedOnce) {
                root.gpuAvailable = false;
                if (!gpuRestartTimer.running)
                gpuRestartTimer.restart();
            }
        }
    }
}
