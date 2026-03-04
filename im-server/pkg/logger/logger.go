package logger

import (
	"sync"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var (
	log  *zap.SugaredLogger
	once sync.Once
)

// Init initializes the global logger. Call once at application startup.
func Init(debug bool) {
	once.Do(func() {
		var cfg zap.Config
		if debug {
			cfg = zap.NewDevelopmentConfig()
			cfg.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
		} else {
			cfg = zap.NewProductionConfig()
		}

		zapLogger, err := cfg.Build(zap.AddCallerSkip(1))
		if err != nil {
			panic("failed to initialize logger: " + err.Error())
		}
		log = zapLogger.Sugar()
	})
}

// getLogger returns the global logger, initializing with defaults if needed.
func getLogger() *zap.SugaredLogger {
	if log == nil {
		Init(false)
	}
	return log
}

// Info logs a message at info level.
func Info(msg string, keysAndValues ...interface{}) {
	getLogger().Infow(msg, keysAndValues...)
}

// Error logs a message at error level.
func Error(msg string, keysAndValues ...interface{}) {
	getLogger().Errorw(msg, keysAndValues...)
}

// Debug logs a message at debug level.
func Debug(msg string, keysAndValues ...interface{}) {
	getLogger().Debugw(msg, keysAndValues...)
}

// Warn logs a message at warn level.
func Warn(msg string, keysAndValues ...interface{}) {
	getLogger().Warnw(msg, keysAndValues...)
}

// Fatal logs a message at fatal level and then calls os.Exit(1).
func Fatal(msg string, keysAndValues ...interface{}) {
	getLogger().Fatalw(msg, keysAndValues...)
}

// Sync flushes any buffered log entries. Should be called before application exit.
func Sync() {
	if log != nil {
		_ = log.Sync()
	}
}
