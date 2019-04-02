module ValueHistoriesLogger

# Imports
using Base.CoreLogging:
    global_logger, LogLevel, Info

import Base.CoreLogging:
    AbstractLogger, handle_message, shouldlog, min_enabled_level,
	catch_exceptions

using ValueHistories

# Exports
export MVLogger, data

# Core Code
"""
	MVLogger <: AbstractLogger

A `Logger` that will save any variable logged to a `MVHistory` object from
`ValueHistories` package.

Any message such as
`@info \"text\" key1=val1 key2=val2`
will result into the keys `text/key1` and `text/key2` with the corresponding
data being logged to the history.

The special key `log_step_increment=1` is always included. If redefined then
this represents by how much the step counter should be incremented.
"""
mutable struct MVLogger <: AbstractLogger
    hist::MVHistory
    min_level::LogLevel
    global_step::Int
end

"""
	MVLogger(level=Info, step=0)

Creates a Multi Value Logger `MVLogger` that will log any message above level
`LogLevel.Info` and current `step` set to 0.
"""
MVLogger(level=Info; step=0)  = MVLogger(MVHistory(), level, step)

"""
	data(logger)

Returns the `MVHistory` object to which the logger logged data.
"""
data(logger::MVLogger) = logger.hist

"""
	set_step(logger, iter)

Sets the step of `logger` to `iter`.
"""
set_step(lg::MVLogger, iter::Int) = lg.global_step = iter

"""
	increment_step(logger, incr)

Increments the step of `logger` by `incr` and returns the new step value.
"""
increment_step(lg::MVLogger, iter::Int) = lg.global_step += iter

"""
	step(logger)

Returns the current step.
"""
step(lg::MVLogger) = lg.global_step

shouldlog(lg::MVLogger, level, _module, group, id) = true

min_enabled_level(lg::MVLogger) = lg.min_level

catch_exceptions(lg::MVLogger) = false

function handle_message(lg::MVLogger, level, message, _module, group, id,
                        filepath, line; maxlog=nothing, kwargs...)
	println("$message", "$kwargs")

    i_step = 1
    for (key, val) in pairs(kwargs)
        if key == :log_step_increment
            i_step = val
            break
        end
    end
    iter = increment_step(lg, i_step)

	!isempty(message) ? message = message*"/" : message = message

    for (key, val) in pairs(kwargs)
        key == :log_step_increment && continue

        push!(lg.hist, Symbol(message, key), iter, deepcopy(val))
    end
end


end # module
