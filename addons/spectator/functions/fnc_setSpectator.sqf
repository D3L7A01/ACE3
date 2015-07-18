/*
 * Author: SilentSpike
 * Sets target unit to the given spectator state
 *
 * Arguments:
 * 0: Unit to put into spectator state <OBJECT>
 * 1: New spectator state <BOOL> <OPTIONAL>
 * 2: Spectator camera target <OBJECT> <OPTIONAL>
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * [player, true] call ace_spectator_fnc_setSpectator
 *
 * Public: Yes
 */

#include "script_component.hpp"

params ["_unit",["_set",true,[true]],["_target",objNull,[objNull]]];

// No change, no service (but allow spectators who respawn to be reset)
if !(_set || (_unit getVariable [QGVAR(isSpectator), false])) exitWith {};

// Only run for player units
if !(isPlayer _unit) exitWith {};

if !(local _unit) exitwith {
    [[_unit, _set, _target], QFUNC(setSpectator), _unit] call EFUNC(common,execRemoteFnc);
};

// Prevent player falling into water
_unit enableSimulation !_set;

// Move to/from group as appropriate
[_unit, _set, QGVAR(isSpectator), side group _unit] call EFUNC(common,switchToGroupSide);

if (_set) then {
    // Move and hide the player ASAP to avoid being seen
    _unit setPos (getMarkerPos QGVAR(respawn));

    // Ghosts can't talk
    [_unit, QGVAR(isSpectator)] call EFUNC(common,hideUnit);
    [_unit, QGVAR(isSpectator)] call EFUNC(common,muteUnit);

    if !(isNull _target) then {
        GVAR(camPos) = getPosASL _target;
        GVAR(camUnit) = _target;
    };

    ["open"] call FUNC(handleInterface);
} else {
    ["close"] call FUNC(handleInterface);

    // Physical beings can talk
    [_unit, QGVAR(isSpectator)] call EFUNC(common,unhideUnit);
    [_unit, QGVAR(isSpectator)] call EFUNC(common,unmuteUnit);

    private "_marker";
    _marker = ["respawn_west","respawn_east","respawn_guerrila","respawn_civilian"] select ([west,east,resistance,civilian] find (side group _unit));
    _unit setPos (getMarkerPos _marker);
};

// Enable/disable input as appropriate
//[QGVAR(isSpectator), _set] call EFUNC(common,setDisableUserInputStatus);

// Handle common addon audio
if (["ace_hearing"] call EFUNC(common,isModLoaded)) then {EGVAR(hearing,disableVolumeUpdate) = _set};
if (["acre_sys_radio"] call EFUNC(common,isModLoaded)) then {[_set] call acre_api_fnc_setSpectator};
if (["task_force_radio"] call EFUNC(common,isModLoaded)) then {[_unit, _set] call TFAR_fnc_forceSpectator};

// Spectators ignore damage (vanilla and ace_medical)
_unit allowDamage !_set;
_unit setVariable [QEGVAR(medical,allowDamage), !_set];

// No theoretical change if an existing spectator was reset
if !(_set && (_unit getVariable [QGVAR(isSpectator), false])) then {
    // Mark spectator state for reference
    _unit setVariable [QGVAR(isSpectator), _set, true];

    ["spectatorChanged",[_set]] call EFUNC(common,localEvent);
};
