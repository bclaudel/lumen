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
    property bool cpuPowerAvailable: false
    property real cpuPowerWatts: 0
    property real cpuClockMhz: NaN
    property var cpuPowerColumns: []

    function resetCpuPower() {
        cpuPowerAvailable = false;
        cpuPowerWatts = 0;
        cpuClockMhz = NaN;
    }

    function parseCpuPower(line) {
        const reading = line.trim();
        if (!reading)
            return;
        const fields = reading.split(/\s+/);
        if (fields.includes("PkgWatt") || fields.includes("Bzy_MHz")) {
            cpuPowerColumns = fields;
            return;
        }
        const watts = parseGpuNumber(fields[cpuPowerColumns.indexOf("PkgWatt")]);
        cpuPowerAvailable = Number.isFinite(watts);
        cpuPowerWatts = cpuPowerAvailable ? watts : 0;
        cpuClockMhz = parseGpuNumber(fields[cpuPowerColumns.indexOf("Bzy_MHz")]);
        cpuPowerStaleTimer.restart();
    }

    property bool gpuAvailable: false
    property real gpuClockMhz: NaN
    property var gpuHistory: []
    property real gpuMemoryTotalMib: NaN
    property real gpuMemoryUsedMib: NaN
    readonly property bool gpuMemoryAvailable: Number.isFinite(gpuMemoryUsedMib) && Number.isFinite(
                                                   gpuMemoryTotalMib) && gpuMemoryTotalMib > 0
    property string gpuName: ""
    property real gpuPowerWatts: NaN
    property real gpuTemperature: NaN
    property real gpuUsage: 0

    property bool memoryAvailable: false
    property var memoryHistory: []
    property real memoryTotalBytes: 0
    property real memoryUsage: 0
    property real memoryUsedBytes: 0
    property real swapTotalBytes: 0
    property real swapUsedBytes: 0

    property bool psuPowerAvailable: false
    property real psuPowerWatts: 0

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

    function invalidateGpu() {
        gpuAvailable = false;
        gpuUsage = 0;
        gpuHistory = [];
        gpuClockMhz = NaN;
        gpuMemoryTotalMib = NaN;
        gpuMemoryUsedMib = NaN;
        gpuPowerWatts = NaN;
        gpuTemperature = NaN;
    }

    function parseGpuNumber(field) {
        if (!field)
            return NaN;
        const value = Number(field);
        return Number.isFinite(value) && value >= 0 ? value : NaN;
    }

    function parseGpuLine(line) {
        const fields = line.split(",").map(field => field.trim());
        if (fields.length < 7) {
            invalidateGpu();
            return;
        }

        const usage = parseGpuNumber(fields[1]);
        gpuName = fields[0];
        gpuAvailable = Number.isFinite(usage);
        gpuUsage = gpuAvailable ? Math.min(100, usage) : 0;
        gpuMemoryUsedMib = parseGpuNumber(fields[2]);
        gpuMemoryTotalMib = parseGpuNumber(fields[3]);
        gpuTemperature = parseGpuNumber(fields[4]);
        gpuPowerWatts = parseGpuNumber(fields[5]);
        gpuClockMhz = parseGpuNumber(fields[6]);
        gpuHistory = gpuAvailable ? appendSample(gpuHistory, gpuUsage) : [];
        gpuStaleTimer.restart();
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
        psuPowerAvailable = false;
        psuPowerWatts = 0;
        try {
            const sensors = JSON.parse(contents);
            for (const deviceName of Object.keys(sensors)) {
                if (!deviceName.startsWith("corsairpsu-"))
                    continue;
                const power = sensors[deviceName]?.["power total"]?.power1_input;
                if (typeof power === "number" && Number.isFinite(power) && power >= 0) {
                    psuPowerWatts = power;
                    psuPowerAvailable = true;
                    break;
                }
            }
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
        interval: 2000
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

    Timer {
        id: gpuStaleTimer

        // Allow several missed samples before hiding a stalled monitor's readings.
        interval: 7000
        onTriggered: root.invalidateGpu()
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

    Timer {
        id: cpuPowerStaleTimer

        interval: 7000
        onTriggered: root.resetCpuPower()
    }

    Timer {
        id: cpuPowerRestartTimer

        interval: 15000
        onTriggered: cpuPowerMonitor.running = true
    }

    Process {
        id: cpuPowerMonitor

        // -n prevents authentication prompts from a background shell service.
        command: ["env", "LC_ALL=C", "sudo", "-n", "/usr/bin/turbostat", "--quiet", "--Summary",
            "--show", "PkgWatt,Bzy_MHz", "--interval", "2"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: line => root.parseCpuPower(line)
        }

        onExited: {
            root.cpuPowerColumns = [];
            cpuPowerStaleTimer.stop();
            root.resetCpuPower();
            cpuPowerRestartTimer.restart();
        }
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
                gpuStaleTimer.stop();
                root.invalidateGpu();
                if (!gpuRestartTimer.running)
                    gpuRestartTimer.restart();
            }
        }
    }
}
