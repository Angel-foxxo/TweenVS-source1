/* Copyright (C) 2023 Angel - All Rights Reserved
 * You may use, distribute and modify this code under the
 * terms of the MIT license.
 *
 * You should have received a copy of the LICENSE file with
 * this file. If not, please write to: angelcazacu8@gmail.com or visit : github.com/Angel-foxxo/TweenVS-source1
*/
local VERSION = "1.0.1";

if("TweenVS" in getroottable())
{
    if(typeof TweenVS == "table")
    {
        if(VERSION != TweenVS.VERSION)
        {
            local v1 = split(VERSION, ".");
            local v2 = split(TweenVS.VERSION, ".");
            local v1_int = format("%s%s%s", v1[0], v1[1], v1[2]).tointeger();
            local v2_int = format("%s%s%s", v2[0], v2[1], v2[2]).tointeger();
            if(v1_int < v2_int)
            {
                printl("------WARNING-----");
                printl(format("-TweenVS: Attempted to load an older version, keeping current script with version(%s), old script has version(%s)", TweenVS.VERSION, VERSION));
                printl("------------------");
                return;
            }
        }
    }
}
else
{
    ::TweenVS <- {};
}

TweenVS.VERSION <- VERSION;
printl(format("TweenVS: Succesfully loaded, version %s", VERSION));
TweenVS.Tweens <- [];

/*
    Main Tween Class
*/
TweenVS.Tween <- class
{
    _target = null;
    _type = null;
    _initVal = null;
    _endVal = null;
    _initTime = null;
    _duration = null;
    _running = null;
    _timeElapsed = null;
    _resultVal = null;
    _callbackUpdateList = null;
    _callbackFinishList = null;
    _callbackStartList = null;
    _callbackEveryStartList = null;
    _callbackStopList = null;
    _nextTween = null;
    _looping = null;
    _loopCount = null;
    _runCount = null;
    _paused = null;
    _pausedTime = null;
    _delay = null;
    _delayTime = null;
    _easingFunction = null;
    _property = null;
    _localVal = null;
    _localLoop = null;
    _inverted = null;
    _snap = null;
    _bounce = null;
    _justLooped = null;
    _quaternionInterp = null;
    _rotationDir = null;


    constructor()
    {
        _target = null;
        _type = null;
        _initVal = null;
        _endVal = null;
        _initTime = null;
        _duration = null;
        _running = false;
        _timeElapsed = 0;
        _resultVal = null;
        _callbackUpdateList = [];
        _callbackFinishList = [];
        _callbackStartList = [];
        _callbackEveryStartList = [];
        _callbackStopList = [];
        _nextTween = null;
        _looping = null;
        _loopCount = null;
        _runCount = 0;
        _paused = false;
        _pausedTime = null;
        _delay = null;
        _delayTime = null;
        _easingFunction = null;
        _property = null;
        _localVal = null;
        _localLoop = null;
        _inverted = false;
        _snap = false;
        _bounce = false;
        _quaternionInterp = false;
        _rotationDir = null;
    }

    function _typeof()
    {
        return "Tween"
    }

    function _tostring()
    {
        //ugly casting to a string but nothing else worked for all values
        return format("Tween : ( StartVal : %s | EndVal : %s | ResultVal : %s )", "" + _initVal, "" + _endVal, "" + _resultVal)
    }

    //get the target to interpolate, the target can be either an entity or a basic type
    function from(target, property = null, dir = 1)
    {
        //set what property we are modifying
        switch(property)
        {
            case TweenVS.EntProps.pos:
            {
                _type = TweenVS.EntProps.pos;

            }; break;

            case TweenVS.EntProps.ang:
            {
                _type = TweenVS.EntProps.ang;
                if(dir != 0 && dir != 1 && dir != -1)
                {
                    throw("TweenVS: from() rotation direction is invalid!");
                }
                if(dir == 0)
                {
                    _quaternionInterp = false
                    _rotationDir = 0
                }
                else
                {
                    _quaternionInterp = true
                    if(dir == 1)
                    {
                        _rotationDir = 1
                    }
                    else if(dir == -1)
                    {
                        _rotationDir = -1
                    }
                }

            }; break;
        }

        //is it an entity?
        if(typeof target == "instance")
        {
            //its an entity!
            if(target instanceof CBaseEntity)
            {
                if(property == null)
                {
                    throw("TweenVS: from() target is an entity but no entity propery is specified!");
                }
                //check if propery is valid
                if(!(property in TweenVS.EntProps))
                {
                    throw("TweenVS: from() target is an entity but the entity property is invalid!");
                }
                //set the property
                switch(_type)
                {
                    case TweenVS.EntProps.pos:
                    {
                        _initVal = target.GetOrigin();

                    }; break;

                    case TweenVS.EntProps.ang:
                    {
                        _initVal = target.GetAngles();

                    }; break;
                }
                _target = target;
                _property = property;
            }

        }
        //not an entity, perhaps a type?
        else if(typeof target in TweenVS.ValTypes)
        {
            //if(property != null)
            //{
            //    throw("TweenVS: only entities use the property field!");
            //}

            _initVal = target;
            _target = target;
        }
        //NEITHER!! WHAT ARE YOU TRYING TO DO!?
        else
        {
            throw("TweenVS: get() target is invalid!");
        }

        return this;
    }

    //target value of the tween, has to match with the initial value type
    function to(value, duration = 1)
    {
        if(_initVal == null)
        {
            throw("TweenVS: start value doesn't exist! did you run from() first?");
        }

        if(typeof value != typeof _initVal)
        {
            //fixme: this is unreadable
            //dont throw an error if the start and end vars are float and int since squirrel autoconverts between them
            if(!((typeof value == "float" && typeof _initVal == "integer") || (typeof _initVal == "float" && typeof value == "integer")))
            {
                throw("TweenVS: start value type doesn't match end value type!");
            }
        }

        if(typeof duration != "integer" && typeof duration != "float")
        {
            throw("TweenVS: tween duration is invalid!");
        }

        _endVal = value;
        _duration = duration;

        return this;
    }

    //only for entities, makes the tween local to the entity
    function toLocal(value, duration = 1, localLoop = false)
    {
        if(_initVal == null)
        {
            throw("TweenVS: start value doesn't exist! did you run from() first?");
        }

        if(typeof _target != "instance")
        {
            throw("TweenVS: toLocal is only meant for entities!");
            if(_target instanceof CBaseEntity)
            {
                throw("TweenVS: toLocal is only meant for entities!");
            }
        }

        _localVal = value
        _localLoop = localLoop
        to(_initVal+value, duration);

        return this;
    }

    //start tweening
    function start()
    {
        if(_localLoop)
        {
            from(_target, _property, _rotationDir);
            toLocal(_localVal, _duration, _localLoop);
        }
        _initTime = Time();
        _timeElapsed = 0;
        _running = true;
        if(TweenVS.FindInArray(TweenVS.Tweens, this) == null)
        {
            _runCount = 0;
            TweenVS.Tweens.push(this);
        }
        return this
    }

    //stops tweening, will actually remove it from the Tweens array
    function stop()
    {
        TweenVS.Tweens.remove(TweenVS.FindInArray(TweenVS.Tweens, this));
        foreach (callback in _callbackStopList)
        {
            if(typeof callback[0] != "function")
            {
                EntFireByHandle( TweenVS.FuncTimer, "Disable", "", 0, null, null );
                throw("TweenVS: on(stop) is attempting to call something that isn't a function!");
            }
            callback[0].call(callback[1], _resultVal);
        }
        return this
    }

    //add a callback function
    function on(type, func)
    {
        if(!(type in TweenVS.Callbacks))
        {
            throw("TweenVS: on() was passed an invalid callback type!");
        }

        local env = getstackinfos(2).locals["this"];

        switch(type)
        {
            case TweenVS.Callbacks.update: { _callbackUpdateList.push([func, env]); }; break;
            case TweenVS.Callbacks.finish: { _callbackFinishList.push([func, env]); }; break;
            case TweenVS.Callbacks.start: { _callbackStartList.push([func, env]); }; break;
            case TweenVS.Callbacks.everyStart: { _callbackEveryStartList.push([func, env]); }; break;
            case TweenVS.Callbacks.stop: { _callbackStopList.push([func, env]); }; break;
        }

        return this
    }

    //pauses the tweening, passing a number in seconds makes it act as a delay
    //otherwise it pauses forever
    function pause(time = null)
    {
        if(_paused == true)
        {
            return this
        }
        _pausedTime = Time();
        _running = false;
        _paused = true;

        if(time != null)
        {
            if(typeof time != "integer" && typeof time != "float")
            {
                throw("TweenVS: delay() has an invalid parameter!");
            }
            _delay = time;
            _delayTime = Time();
        }

        return this
    }

    //unpauses a tween, does nothing if its not paused
    function unpause()
    {
        if(!_initTime)
        {
            return this
        }
        if(_paused != true)
        {
            return this
        }
        if(_delay != null)
        {
            return this
        }
        local resumeTime = Time();
        _initTime = resumeTime - (_pausedTime -_initTime);
        _running = true;
        _paused = false;
        return this
    }

    //loops the tween, loopCount of -1 is infinite looping
    function loop(loopCount = null)
    {
        if(typeof loopCount != "integer" && typeof loopCount != "float" && loopCount != null)
        {
            throw("TweenVS: loop() has an invalid parameter!");
        }
        _looping = true;
        _loopCount = loopCount;
        if(loopCount == 0)
        {
            _looping = false;
            _loopCount = 0;
        }
        if(loopCount < 0)
        {
            _looping = true;
            _loopCount = null;
        }
        return this
    }

    //makes the tween reverse direction at the end of each loop
    //each start of the tween in a single direction counts as a single bounce, for example
    //to play a tween once forward, and once back, set the loop() function to 1
    function bounce(val = true)
    {
        if(typeof val != "bool")
        {
            throw("TweenVS: bounce() has an invalid parameter!");
        }
        _bounce = val;

        return this
    }

    //runs the provided tween when the current tween finishes
    function chain(tween = null)
    {
        if(tween == null)
        {
            throw("TweenVS: chain() is missing a value!");
        }
        if(typeof tween != "Tween")
        {
            throw("TweenVS: chain() was pass an invalid value!");
        }
        _nextTween = tween;
        return this
    }

    //sets the easing function, leave black for linear interpolation
    //you can either use a function from TweenVS.EasingFunctions or
    //pass a custom function, the function needs to take one parameter (t)
    //and return the modified t parameter
    function easing(easingFunction = null)
    {
        if(easingFunction != null && typeof easingFunction != "function")
        {
            throw("TweenVS: easing() has an invalid parameter!");
        }

        _easingFunction = easingFunction;

        return this
    }

    //inverts the tween, this does not modify the _initVal and _endVal variables like bounce()
    //but is instead done by inverting the t value used to interpolate
    function invert(val = true)
    {
        if(typeof val != "bool")
        {
            throw("TweenVS: invert() has an invalid parameter!");
        }
        _inverted = val;

        return this
    }

    //toggles snapping at the start/end of the tween
    function snap(val = true)
    {
        if(typeof val != "bool")
        {
            throw("TweenVS: snap() has an invalid parameter!");
        }
        _snap = val;

        return this
    }

    //read more in the function, this shit does too much stuff to write it all here
    function update()
    {

        if(_delay != null)
        {
            if(Time() - _delayTime <  _delay)
            {
                return
            }
            else
            {
                _delay = null;
                unpause();
            }
        }

        if(!_running)
        {
            return
        }

        _timeElapsed = Time() - _initTime;

        //horrible hack to fix the tween not starting from the initial value on loops due to execution order
        if(_justLooped)
        {
            _timeElapsed = 0
            _justLooped = false
        }

        if(_timeElapsed < _duration)
        {
            local t = _timeElapsed/_duration;

            if(_easingFunction == null)
            {
                t = t;
            }
            else
            {
                t = _easingFunction(t);
            }

            if(_inverted)
            {
                t = (t * -1) + 1;
            }

            if(t > 1)
            {
                t = 1
            }
            if(t < 0)
            {
                t = 0
            }

            if(_quaternionInterp)
            {
                local _initValQuat = TweenVS.AngleQuaternion(_initVal)
                local _endValQuat = TweenVS.AngleQuaternion(_endVal)
                _resultVal = TweenVS.QuaternionSlerp(_initValQuat, _endValQuat, t, this)
                _resultVal = TweenVS.QuaternionAngles(_resultVal)
            }
            else
            {
                _resultVal = TweenVS.Lerp(_initVal, _endVal, t);
            }

            if(_timeElapsed == 0)
            {
                foreach (callback in _callbackEveryStartList)
                {
                    if(typeof callback[0] != "function")
                    {
                        EntFireByHandle( TweenVS.FuncTimer, "Disable", "", 0, null, null );
                        throw("TweenVS: on(everyStart) is attempting to call something that isn't a function!");
                    }
                    callback[0].call(callback[1], _resultVal);
                }
            }

        }
        else
        {
            _resultVal = _endVal;
            _runCount++
            _running = false;
            foreach (callback in _callbackFinishList)
            {
                if(typeof callback[0] != "function")
                {
                    EntFireByHandle( TweenVS.FuncTimer, "Disable", "", 0, null, null );
                    throw("TweenVS: on(update) is attempting to call something that isn't a function!");
                }

                callback[0].call(callback[1], _resultVal);
            }

            if(_looping)
            {
                if(_loopCount == null || _runCount <= _loopCount)
                {
                    if(_bounce)
                    {
                        local tempInitVal = _initVal
                        local tempEndVal = _endVal
                        _initVal = tempEndVal
                        _endVal = tempInitVal
                    }
                    _justLooped = true;
                    start();
                }
            }
        }
        if(typeof _target == "instance")
        {
            //its an entity!
            if(_target instanceof CBaseEntity)
            {
                //set entity property based on the type
                switch(_type)
                {
                    //using the native vscript function to set the data disables interpolation
                    //so its used on the first update call to "snap" the animation then the data
                    //is set directly so the engine can interpolate the entity, this allows the
                    //tween to look smooth even when host_timescale is set to a low value
                    //it can be toggles using snap() since in some cases this behavior may
                    //not be disireable
                    case TweenVS.EntProps.pos:
                    {
                        if(_timeElapsed == 1 && _snap)
                        {
                            _target.SetOrigin(_resultVal);
                        }
                        else
                        {
                            _target.__KeyValueFromVector("origin", _resultVal);
                        }

                    }; break;

                    case TweenVS.EntProps.ang:
                    {

                        if(_timeElapsed == 1 && _snap)
                        {
                            _target.SetAngles(_resultVal.x, _resultVal.y, _resultVal.z);
                        }
                        else
                        {
                            //for some reason setting angles from keyvalue on players doesnt work
                            if(_target.GetClassname() == "player" || _target.GetClassname() == "cs_bot")
                            {
                                _target.SetAngles(_resultVal.x, _resultVal.y, _resultVal.z);
                            }
                            _target.__KeyValueFromVector("angles", _resultVal);
                        }

                    }; break;
                }
            }
        }
        //not an entity, perhaps a type?
        else if(typeof _target in TweenVS.ValTypes)
        {
            _target = _resultVal;
        }

        foreach (callback in _callbackUpdateList)
        {
            if(typeof callback[0] != "function")
            {
                EntFireByHandle( TweenVS.FuncTimer, "Disable", "", 0, null, null );
                throw("TweenVS: on(start) is attempting to call something that isn't a function!");
            }
            callback[0].call(callback[1], _resultVal);
        }

        if(_runCount == 0 && _timeElapsed == 0)
        {
            foreach (callback in _callbackStartList)
            {
                if(typeof callback[0] != "function")
                {
                    EntFireByHandle( TweenVS.FuncTimer, "Disable", "", 0, null, null );
                    throw("TweenVS: on(start) is attempting to call something that isn't a function!");
                }
                callback[0].call(callback[1], _resultVal);
            }
        }

        //twin chaining is executed here because otherwise we wouldnt get the final start position
        if(_nextTween != null && _timeElapsed >= _duration)
        {
            _nextTween.start();
            if(_nextTween._paused)
            {
                _nextTween._paused = false
                _nextTween.pause(_nextTween._delay)
            }
        }

    }
}

/*
    Util functions
*/
TweenVS.Lerp <- function(a, b, t)
{
    return (a * (1.0 - t)) + (b * t);
}

TweenVS.FindInArray <- function(arr, thingToFind)
{
    for (local i = 0; i < arr.len(); i++)
    {
        if (arr[i] == thingToFind)
        {
            return i;
        }
    }

    return null;
}
//internal quaternion for slerping angles
TweenVS.Quaternion <- class
{
    x = 0.0;
    y = 0.0;
    z = 0.0;
    w = 0.0;

    constructor(_x = 0.0, _y = 0.0, _z = 0.0, _w = 0.0)
    {
        x = _x;
        y = _y;
        z = _z;
        w = _w;
    }

    function _typeof()
	{
		return "TweenVS Quaternion";
	}

    function _tostring()
    {
        return format("Quaternion : (%f, %f, %f, %f)", x, y, z, w)
    }

    function _add(v)
    {
        return TweenVS.Quaternion(x + v.x, y + v.y, z + v.z, w + v.w)
    }

    function _sub(v)
    {
        return TweenVS.Quaternion(x - v.x, y - v.y, z - v.z, w - v.w)
    }

    function _mul(v)
    {
        return TweenVS.Quaternion(x * v, y * v, z * v, w * v)
    }

    function _unm()
    {
        return TweenVS.Quaternion(-x, -y, -z, -w)
    }

    function invert()
    {
        local length = sqrt(x * x + y * y + z * z + w * w);

        return TweenVS.Quaternion(-x / length, -y / length, -z / length, w / length)

    }
}

/*
    Tween Value Types
*/
TweenVS.ValTypes <-
{
    integer = "integer",
    float = "float",
    Vector = "Vector",
}

/*
    Entity Properties
*/
TweenVS.EntProps <-
{
    pos = "pos",
    ang = "ang"
}

/*
    Tween Callback Function Types
*/
TweenVS.Callbacks <-
{
    update = "update",
    finish = "finish",
    start = "start",
    everyStart = "everyStart",
    stop = "stop"
}

/*
    Tween Update Function
*/
function TweenVS::UpdateTweens()
{
    foreach (i, Tween in TweenVS.Tweens)
    {

        if(Tween._initVal == null)
        {
            EntFireByHandle( TweenVS.FuncTimer, "Disable", "", 0, null, null );
            throw("TweenVS: Updating Tween without a start value!");
        }
        if(Tween._endVal == null)
        {
            EntFireByHandle( TweenVS.FuncTimer, "Disable", "", 0, null, null );
            throw("TweenVS: Updating Tween without an end value!");
        }

        Tween.update();
    }
}
if(!("FuncTimer" in TweenVS))
{
    TweenVS.FuncTimer <- Entities.CreateByClassname( "logic_timer" );
    TweenVS.FuncTimer.__KeyValueFromFloat( "RefireTime", FrameTime() );
    TweenVS.FuncTimer.ValidateScriptScope();
    TweenVS.FuncTimer.GetScriptScope().OnTimer <- TweenVS.UpdateTweens;
    TweenVS.FuncTimer.ConnectOutput( "OnTimer", "OnTimer" );
    TweenVS.FuncTimer.__KeyValueFromString("classname", "soundent");
    EntFireByHandle( TweenVS.FuncTimer, "Enable", "", 0, null, null );
}
else
{
    EntFireByHandle( TweenVS.FuncTimer, "Enable", "", 0, null, null );
}

/*
    Easing Functions
    taken from https://easings.net/
*/
TweenVS.EaseInSine <- function(t)
{
    return 1.0 - cos((t * PI) / 2.0);
}

TweenVS.EaseOutSine <- function(t)
{
    return sin((t * PI) / 2);
}

TweenVS.EaseInOutSine <- function(t)
{
    return -(cos(PI * t) - 1.0) / 2.0;
}

TweenVS.EaseInCubic <- function(t)
{
    return t * t * t;
}

TweenVS.EaseOutCubic <- function(t)
{
    return 1.0 - pow(1.0 - t, 3.0);
}

TweenVS.EaseInOutCubic <- function(t)
{
    return t < 0.5 ? (4.0 * t * t * t) : (1 - pow(-2.0 * t + 2.0, 3.0) / 2.0);
}

TweenVS.EaseInQuint <- function(t)
{
    return t * t * t * t * t;
}

TweenVS.EaseOutQuint <- function(t)
{
    return 1.0 - pow(1.0 - t, 5.0);
}

TweenVS.EaseInOutQuint <- function(t)
{
    return t < 0.5 ? (16.0 * t * t * t * t * t) : 1.0 - pow(-2.0 * t + 2.0, 5.0) / 2.0;
}

TweenVS.EaseInCircle <- function(t)
{
    return 1.0 - sqrt(1.0 - pow(t, 2.0));
}

TweenVS.EaseOutCircle <- function(t)
{
    return sqrt(1.0 - pow(t - 1.0, 2.0));
}

TweenVS.EaseInOutCircle <- function(t)
{
    return t < 0.5
    ? (1.0 - sqrt(1.0 - pow(2.0 * t, 2.0))) / 2.0
    : (sqrt(1.0 - pow(-2.0 * t + 2.0, 2.0)) + 1.0) / 2.0;
}

TweenVS.EaseInElastic <- function(t)
{
    local c4 = (2.0 * PI) / 3.0;

    return t == 0
    ? 0
    : t == 1.0
    ? 1.0
    : -pow(2.0, 10.0 * t - 10.0) * sin((t * 10.0 - 10.75) * c4);
}

TweenVS.EaseOutElastic <- function(t)
{
    local c4 = (2.0 * PI) / 3.0;

    return t == 0
    ? 0
    : t == 1.0
    ? 1.0
    : pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0;
}

TweenVS.EaseInOutElastic <- function(t)
{
    local c5 = (2.0 * PI) / 4.5;

    return t == 0
    ? 0
    : t == 1
    ? 1
    : t < 0.5
    ? -(pow(2.0, 20.0 * t - 10.0) * sin((20.0 * t - 11.125) * c5)) / 2.0
    : (pow(2.0, -20.0 * t + 10.0) * sin((20.0 * t - 11.125) * c5)) / 2.0 + 1.0;
}

TweenVS.EaseInQuad <- function(t)
{
    return t * t;
}

TweenVS.EaseOutQuad <- function(t)
{
    return 1.0 - (1.0 - t) * (1.0 - t);
}

TweenVS.EaseInOutQuad <- function(t)
{
    return t < 0.5 ? (2.0 * t * t) : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;
}

TweenVS.EaseInQuart <- function(t)
{
    return t * t * t * t;
}

TweenVS.EaseOutQuart <- function(t)
{
    return 1.0 - pow(1.0 - t, 4.0)
}

TweenVS.EaseInOutQuart <- function(t)
{
    return t < 0.5 ? (8.0 * t * t * t * t) : 1.0 - pow(-2.0 * t + 2.0, 4.0) / 2.0;
}

TweenVS.EaseInExpo <- function(t)
{
    return t == 0 ? 0 : pow(2.0, 10.0 * t - 10.0);
}

TweenVS.EaseOutExpo <- function(t)
{
    return t == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * t);
}

TweenVS.EaseInOutExpo <- function(t)
{
    return t == 0
    ? 0
    : t == 1.0
    ? 1.0
    : t < 0.5 ? pow(2.0, 20.0 * t - 10.0) / 2.0
    : (2.0 - pow(2.0, -20.0 * t + 10.0)) / 2.0;
}

TweenVS.EaseInBack <- function(t)
{
    local c1 = 1.70158;
    local c3 = c1 + 1;

    return c3 * t * t * t - c1 * t * t;
}

TweenVS.EaseOutBack <- function(t)
{
    local c1 = 1.70158;
    local c3 = c1 + 1;

    return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0);
}

TweenVS.EaseInOutBack <- function(t)
{
    local c1 = 1.70158;
    local c2 = c1 * 1.525;

    return t < 0.5
    ? (pow(2.0 * t, 2.0) * ((c2 + 1.0) * 2.0 * t - c2)) / 2.0
    : (pow(2.0 * t - 2.0, 2.0) * ((c2 + 1.0) * (t * 2.0 - 2.0) + c2) + 2.0) / 2.0;
}

TweenVS.EaseInBounce <- function(t)
{
    return 1 - TweenVS.EaseOutBounce(1 - t);
}

TweenVS.EaseOutBounce <- function(t)
{
    local n1 = 7.5625;
    local d1 = 2.75;

    if (t < 1.0 / d1)
    {
        return n1 * t * t;
    }
    else if (t < 2.0 / d1)
    {
        return n1 * (t -= 1.5 / d1) * t + 0.75;
    }
    else if (t < 2.5 / d1)
    {
        return n1 * (t -= 2.25 / d1) * t + 0.9375;
    }
    else
    {
        return n1 * (t -= 2.625 / d1) * t + 0.984375;
    }
}

TweenVS.EaseInOutBounce <- function(t)
{
    return t < 0.5
    ? (1.0 - TweenVS.EaseOutBounce(1.0 - 2.0 * t)) / 2.0
    : (1.0 + TweenVS.EaseOutBounce(2.0 * t - 1.0)) / 2.0;
}

TweenVS.EasingFunctions <-
[
    TweenVS.EaseInSine,
    TweenVS.EaseOutSine,
    TweenVS.EaseInOutSine,
    TweenVS.EaseInCubic,
    TweenVS.EaseOutCubic,
    TweenVS.EaseInOutCubic,
    TweenVS.EaseInQuint,
    TweenVS.EaseOutQuint,
    TweenVS.EaseInOutQuint,
    TweenVS.EaseInCircle,
    TweenVS.EaseOutCircle,
    TweenVS.EaseInOutCircle,
    TweenVS.EaseInElastic,
    TweenVS.EaseOutElastic,
    TweenVS.EaseInOutElastic,
    TweenVS.EaseInQuad,
    TweenVS.EaseOutQuad,
    TweenVS.EaseInQuart,
    TweenVS.EaseOutQuart,
    TweenVS.EaseInOutQuart,
    TweenVS.EaseInExpo,
    TweenVS.EaseOutExpo,
    TweenVS.EaseInOutExpo,
    TweenVS.EaseInBack,
    TweenVS.EaseOutBack,
    TweenVS.EaseInOutBack,
    TweenVS.EaseInBounce,
    TweenVS.EaseOutBounce,
    TweenVS.EaseInOutBounce
]

//taken from vs_library https://github.com/samisalreadytaken/vs_library
/*LICENSE
-Copyright (c) samisalreadytaken
-
-Permission is hereby granted, free of charge, to any person obtaining a copy
-of this software and associated documentation files (the "Software"), to deal
-in the Software without restriction, including without limitation the rights
-to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-copies of the Software, and to permit persons to whom the Software is
-furnished to do so, subject to the following conditions:
-
-The above copyright notice and this permission notice shall be included in all
-copies or substantial portions of the Software.
-
-THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-SOFTWARE.
*/
const DEG2RAD			= 0.017453293;;			// PI / 180 = 0.01745329251994329576
const RAD2DEG			= 57.295779513;;
const PIDIV2			= 1.570796327;;			// 1.57079632679489661923

TweenVS.QuaternionSlerpNoAlign <- function(p, q, t)
{
	local sclp, sclq;
    local qt = TweenVS.Quaternion()
	// QuaternionDotProduct
	local cosom = p.x*q.x + p.y*q.y + p.z*q.z + p.w*q.w;

	if ( cosom > -0.999999 ) // ( (1.0 + cosom) > 0.000001 )
	{
		if ( cosom < 0.999999 ) // ( (1.0 - cosom) > 0.000001 )
		{
			local omega = acos( cosom );
			local invSinom = 1.0 / sin( omega );
			sclp = sin( (1.0 - t)*omega ) * invSinom;
			sclq = sin( t*omega ) * invSinom;
		}
		else
		{
			// TODO: add short circuit for cosom == 1.0?
			sclp = 1.0 - t;
			sclq = t;
		};

		qt.x = sclp * p.x + sclq * q.x;
		qt.y = sclp * p.y + sclq * q.y;
		qt.z = sclp * p.z + sclq * q.z;
		qt.w = sclp * p.w + sclq * q.w;
	}
	else
	{
		// Assert( qt != q );

		// qt.x = -q.y;
		// qt.y = q.x;
		// qt.z = -q.w;
		// qt.w = q.z;
		sclp = sin( (1.0 - t) * PIDIV2 );
		sclq = sin( t * PIDIV2 );

		qt.x = sclp * p.x - sclq * q.y;
		qt.y = sclp * p.y + sclq * q.x;
		qt.z = sclp * p.z - sclq * q.w;
		qt.w = sclp * p.w + sclq * q.z;
	};

	return qt;
}
TweenVS.QuaternionAlign <- function(p, q)
{
    local qt = TweenVS.Quaternion()
	local px = p.x,
		py = p.y,
		pz = p.z,
		pw = p.w,
		qx = q.x,
		qy = q.y,
		qz = q.z,
		qw = q.w;

	// a = dot(p-q)
	// b = dot(p+q)
	local a =
		(px-qx)*(px-qx)+(py-qy)*(py-qy)+
		(pz-qz)*(pz-qz)+(pw-qw)*(pw-qw);
	local b =
		(px+qx)*(px+qx)+(py+qy)*(py+qy)+
		(pz+qz)*(pz+qz)+(pw+qw)*(pw+qw);

	if ( a > b )
	{
		qt.x = -qx;
		qt.y = -qy;
		qt.z = -qz;
		qt.w = -qw;
	}
	else if ( qt != q )
	{
		qt.x = qx;
		qt.y = qy;
		qt.z = qz;
		qt.w = qw;
	};;

	return qt;
}
TweenVS.QuaternionSlerp <- function(q1, q2, t, tween)
{
    if(tween._rotationDir == -1)
    {
        return TweenVS.QuaternionSlerpNoAlign( q1, TweenVS.QuaternionAlign( -q1, -q2 ), t);
    }
    else if(tween._rotationDir == 1)
    {
        return TweenVS.QuaternionSlerpNoAlign( q1, TweenVS.QuaternionAlign( q1, q2 ), t);
    }
}
TweenVS.AngleQuaternion <- function(_QAngle)
{
    local DEG2RADDIV2 = 0.008726646
    local outQuat = TweenVS.Quaternion()
    local ay = _QAngle.y * DEG2RADDIV2,
	ax = _QAngle.x * DEG2RADDIV2,
	az = _QAngle.z * DEG2RADDIV2,
	sy = sin(ay), cy = cos(ay),
	sp = sin(ax), cp = cos(ax),
	sr = sin(az), cr = cos(az),
	srcp = sr * cp,
	crsp = cr * sp,
	crcp = cr * cp,
	srsp = sr * sp;
	outQuat.x = srcp * cy - crsp * sy;
	outQuat.y = crsp * cy + srcp * sy;
	outQuat.z = crcp * sy - srsp * cy;
	outQuat.w = crcp * cy + srsp * sy;

    return outQuat
}
TweenVS.QuaternionAngles <- function(_Quaternion, angles = Vector(0, 0, 0))
{
    // FIXME: doing it this way calculates too much data, needs to do an optimized version...
	local matrix = matrix3x4_t();
	QuaternionMatrix( _Quaternion, null, matrix );
	return MatrixAngles( matrix, angles );
}
TweenVS.matrix3x4_t <- class
{
	[0] = null;

	constructor(
		m00 = 0.0, m01 = 0.0, m02 = 0.0, m03 = 0.0,
		m10 = 0.0, m11 = 0.0, m12 = 0.0, m13 = 0.0,
		m20 = 0.0, m21 = 0.0, m22 = 0.0, m23 = 0.0 )
	{
		this[0] =
		[
			m00, m01, m02, m03,
			m10, m11, m12, m13,
			m20, m21, m22, m23
		];
	}

	function Init(
		m00 = 0.0, m01 = 0.0, m02 = 0.0, m03 = 0.0,
		m10 = 0.0, m11 = 0.0, m12 = 0.0, m13 = 0.0,
		m20 = 0.0, m21 = 0.0, m22 = 0.0, m23 = 0.0 )
	{
		local m = this[0];

		m[M_00] = m00;
		m[M_01] = m01;
		m[M_02] = m02;
		m[M_03] = m03;

		m[M_10] = m10;
		m[M_11] = m11;
		m[M_12] = m12;
		m[M_13] = m13;

		m[M_20] = m20;
		m[M_21] = m21;
		m[M_22] = m22;
		m[M_23] = m23;
	}

	// FLU
	function InitXYZ( vX, vY, vZ, vT )
	{
		local m = this[0];

		m[M_00] = vX.x;
		m[M_10] = vX.y;
		m[M_20] = vX.z;

		m[M_01] = vY.x;
		m[M_11] = vY.y;
		m[M_21] = vY.z;

		m[M_02] = vZ.x;
		m[M_12] = vZ.y;
		m[M_22] = vZ.z;

		m[M_03] = vT.x;
		m[M_13] = vT.y;
		m[M_23] = vT.z;
	}

	function _cloned( src )
	{
		this[0] = clone src[0];
	}

	function _tostring()
	{
		local m = this[0];
		return format( "[ (%.6g, %.6g, %.6g), (%.6g, %.6g, %.6g), (%.6g, %.6g, %.6g), (%.6g, %.6g, %.6g) ]",
			m[M_00], m[M_01], m[M_02],
			m[M_10], m[M_11], m[M_12],
			m[M_20], m[M_21], m[M_22],
			m[M_03], m[M_13], m[M_23] );
	}

	function _typeof()
	{
		return "matrix3x4_t";
	}

	_man = null;

}
const M_00 = 0;;  const M_01 = 1;;  const M_02 = 2;;  const M_03 = 3;;
const M_10 = 4;;  const M_11 = 5;;  const M_12 = 6;;  const M_13 = 7;;
const M_20 = 8;;  const M_21 = 9;;  const M_22 = 10;; const M_23 = 11;;
const M_30 = 12;; const M_31 = 13;; const M_32 = 14;; const M_33 = 15;;
TweenVS.QuaternionMatrix <- function( q, pos, matrix )
{
	matrix = matrix[0];
/*
#if 1
	matrix[0][0] = 1.0 - 2.0 * q.y * q.y - 2.0 * q.z * q.z;
	matrix[1][0] = 2.0 * q.x * q.y + 2.0 * q.w * q.z;
	matrix[2][0] = 2.0 * q.x * q.z - 2.0 * q.w * q.y;
	matrix[0][1] = 2.0 * q.x * q.y - 2.0 * q.w * q.z;
	matrix[1][1] = 1.0 - 2.0 * q.x * q.x - 2.0 * q.z * q.z;
	matrix[2][1] = 2.0 * q.y * q.z + 2.0 * q.w * q.x;
	matrix[0][2] = 2.0 * q.x * q.z + 2.0 * q.w * q.y;
	matrix[1][2] = 2.0 * q.y * q.z - 2.0 * q.w * q.x;
	matrix[2][2] = 1.0 - 2.0 * q.x * q.x - 2.0 * q.y * q.y;
	matrix[0][3] = 0.0;
	matrix[1][3] = 0.0;
	matrix[2][3] = 0.0;
#else
*/
	local x = q.x, y = q.y, z = q.z, w = q.w;
	local x2 = x + x,
		y2 = y + y,
		z2 = z + z,
		xx = x * x2,
		xy = x * y2,
		xz = x * z2,
		yy = y * y2,
		yz = y * z2,
		zz = z * z2,
		wx = w * x2,
		wy = w * y2,
		wz = w * z2;

	matrix[M_00] = 1.0 - (yy + zz);
	matrix[M_10] = xy + wz;
	matrix[M_20] = xz - wy;

	matrix[M_01] = xy - wz;
	matrix[M_11] = 1.0 - (xx + zz);
	matrix[M_21] = yz + wx;

	matrix[M_02] = xz + wy;
	matrix[M_12] = yz - wx;
	matrix[M_22] = 1.0 - (xx + yy);

	if (pos)
	{
		matrix[M_03] = pos.x;
		matrix[M_13] = pos.y;
		matrix[M_23] = pos.z;
	}
	else
	{
		matrix[M_03] = matrix[M_13] = matrix[M_23] = 0.0;
	};
}
TweenVS.MatrixAngles <- function( matrix, angles = Vector(0, 0, 0), position = null )
{
	matrix = matrix[0];

	if ( position )
	{
		// MatrixGetColumn( matrix, 3, position );
		position.x = matrix[M_03];
		position.y = matrix[M_13];
		position.z = matrix[M_23];
	};

	local forward0 = matrix[M_00];
	local forward1 = matrix[M_10];
	local xyDist = sqrt( forward0 * forward0 + forward1 * forward1 );

	// enough here to get angles?
	if( xyDist > 0.001 )
	{
		// (yaw)	y = ATAN( forward[1], forward[0] );		-- in our space, forward is the X axis
		angles.y = atan2( forward1, forward0 ) * RAD2DEG;

		// (pitch)	x = ATAN( -forward[2], sqrt(forward[0]*forward[0]+forward[1]*forward[1]) );
		angles.x = atan2( -matrix[M_20], xyDist ) * RAD2DEG;

		// (roll)	z = ATAN( left[2], up[2] );
		angles.z = atan2( matrix[M_21], matrix[M_22] ) * RAD2DEG;
	}
	else	// forward is mostly Z, gimbal lock-
	{
		// (yaw)	y = ATAN( -left[0], left[1] );			-- forward is mostly z, so use right for yaw
		angles.y = atan2( -matrix[M_01], matrix[M_11] ) * RAD2DEG;

		// (pitch)	x = ATAN( -forward[2], sqrt(forward[0]*forward[0]+forward[1]*forward[1]) );
		angles.x = atan2( -matrix[M_20], xyDist ) * RAD2DEG;

		// Assume no roll in this case as one degree of freedom has been lost (i.e. yaw == roll)
		angles.z = 0.0;
	};

	return angles;
}