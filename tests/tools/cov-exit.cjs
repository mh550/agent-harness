// The coverage measurement's preload (tests/tools/coverage.sh: NODE_OPTIONS=--require=<this file>). node writes its
// NODE_V8_COVERAGE file only when it exits by itself, and the harness ends its resident helper with TERM (helper_stop,
// lib/record.sh): this turns a TERM into an exit with the status a shell reads off the signal (143), so the helper's
// coverage is written. Only the measurement loads it; nothing in lib/ knows it.
process.on("SIGTERM", () => process.exit(143));
