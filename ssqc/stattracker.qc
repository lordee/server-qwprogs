enum
{
    ST_GAMESTART,
    ST_CHANGENAME,
    ST_CHANGETEAM,
    ST_CHANGECLASS,
    ST_DISCONNECTED,
    ST_CONNECTED,
    ST_BECAMEPLAYER,
    ST_BECAMESPECTATOR,
    ST_CHAT,
    ST_BROADCAST
};

void bprint(float msglvl, string s, optional string s2, optional string s3, optional string s4, optional string s5, optional string s6, optional string s7) 
{
    StatTracker.BroadcastMessage(ST_BROADCAST, msglvl, s, s2, s3, s4, s5, s6, s7);
    bprint_engine(msglvl, s, s2, s3, s4, s5, s6, s7);
}

// TODO napalm??
float IsGrenNotWeapon(entity inflictor)
{
    switch (inflictor.weapon)
    {
        case DMSG_GREN_HAND:
        case DMSG_GREN_NAIL:
        case DMSG_GREN_MIRV:
        case DMSG_GREN_GAS:
        case DMSG_GREN_EMP:
        case DMSG_GREN_EMP_AMMO:
        case DMSG_GREN_FLASH:
        case DMSG_GREN_CALTROP:
        case DMSG_GREN_NAPALM:
            return TRUE;
    }

    return FALSE;
}

/*
// in game stats
touches
caps
kill on flag carrier
time

// chat log?

*/

class FO_StatTracker
{
    float RequestID;
    string URL;
    float GameID;
    float GameStartReqID; // used to track request id of game init, so we can set gameid

    void FO_StatTracker; // constructor
    virtual void(float stateType) GameStateChange;
    virtual void(float stateType, entity player) PlayerStateChange;
    virtual void(float stateType) BroadcastMessage;
    virtual void(entity targ, entity inflictor, entity attacker, float damage) Damage;
    virtual void() Shoot;
    virtual void(string endpoint, string data) PostData;
};

FO_StatTracker StatTracker; // global

void FO_StatTracker :: FO_StatTracker(void)
{
    RequestID = 0;
    URL = "http://localhost:5000/api/SSQCStats";
    GameID = 0;
    GameStartReqID = 0;
}

void FO_StatTracker :: PostData(string endpoint, string data)
{
    string url = strcat(this.URL, "/", endpoint);
    data = strcat("{", data, "}");
    
    uri_post(url, this.RequestID, "application/json", data);

    this.RequestID = this.RequestID + 1;
    dprint(strcat(url,"\n"));
    dprint(strcat(data,"\n"));
}

// TODO check that nailgun etc sends shooting packet every frame... also look at bundling them
void FO_StatTracker :: Shoot(entity player, float weaponTypef, float isGren)
{
    string endpoint = "Shoot";
    string event;
    string weaponType = WeaponToString(weaponTypef, isGren);
    event = strcat("\"TF_ID\":", ftos(player.tf_id), ", \"WeaponType\": \"", weaponType, "\", \"Shot_ID\":", player.shot_id, " \"GameTime\":", gameTime);
    event = strcat(event, "\"GameID\":", ftos(this.GameID));

    this.PostData(endpoint, event);
}

float IsCritHit(float weapon, float damage);
// damage done, shot hit, killed
void FO_StatTracker :: Damage(entity targ, entity inflictor, entity attacker, float damage)
{
    if (this.GameID == 0)
        return;
    string endpoint = "Damage";
    // TODO t_damage calls this but most fields might not be set?
    float isCrit = IsCritHit(inflictor.weapon, damage); // direct/full damage
    float shotID = inflictor.shot_id; // player or missile
    float killed = (targ.health <= 0) ? 1 : 0;

    // this is in a random place in TF_T_Damage, I'm not going to track down why, just repeat it here.. probably could be rearranged though to not do same logic twice
    if ((inflictor.classname == "detpack")
            && (inflictor.weaponmode == 1) && (inflictor.enemy == targ))
            damagetypef = DMSG_DETPACK_DIS;
    // TODO disarm stuff above?
    string damageType = DMSGToString(inflictor.weapon);
    float isGren = IsGrenNotWeapon(inflictor);
    string weaponType = WeaponToString(inflictor.weapontype, isGren);

    // if not in water
    // calc midheight distance between targ origin and ground
    float vheight = 0;
    if (targ.waterlevel == 0)
    {
        targ.origin
        vector end;
        end = targ.origin;
        end_z = end_z - 10000;
        traceline(targ.origin, end, MOVE_NOMONSTERS, targ);
        vheight = vlen(targ.origin - trace_endpos); // vertical height (midairs)
    }
    
    string event;
    event = strcat("\"Attacker\": {\"TF_ID\": ", ftos(attacker.tf_id), ", \"ClassName\": \"", attacker.classname, "\", \"Team\":", ftos(attacker.team_no), ", \"Class\":", ftos(attacker.playerclass));
    event = strcat(event, "}, \"Target\": {\"TF_ID\": ", ftos(targ.tf_id), ", \"ClassName\": \"", targ.classname, "\", \"Team\":", ftos(targ.team_no), ", \"Class\":", ftos(targ.playerclass));
    event = strcat(event, "}, \"WeaponType\": \"", weaponType, "\", \"Damage\":", ftos(damage), ", \"Shot_ID\":", ftos(shotID));
    event = strcat(event, ", \"VHeight\":", ftos(vheight), ", \"Killed\":", ftos(killed), ", \"GameTime:\":", ftos(gameTime));
    event = strcat(event, ", \"GameID\": ", ftos(this.GameID), ", \"DeathType\": \"", damageType, "\"");

    this.PostData(endpoint, event);
}

// TODO finish this
void FO_StatTracker :: BroadcastMessage(float stateType, float msglvl, string s, optional string s2, 
        optional string s3, optional string s4, optional string s5, optional string s6, optional string s7)
{
    if (this.GameID == 0)
        return;

    switch (stateType)
    {
        case ST_CHAT:
            dprint("not implemented");
            break;
        case ST_BROADCAST:
            dprint("not implemented");
            break;
    }
}

void FO_StatTracker :: PlayerStateChange(float stateType, entity player)
{
    if (this.GameID == 0)
        return;

    string endpoint = "PlayerStateChange";
    string event = "";
    string eventType = "";
    float gameTime = 0;

    switch (stateType)
    {
        case ST_CHANGENAME:
            eventType = "ChangeName";
            break;
        case ST_CHANGETEAM:
            eventType = "ChangeTeam";
            break;
        case ST_CHANGECLASS:
            eventType = "ChangeClass";
            break;
        case ST_DISCONNECTED:
            eventType = "Disconnected";
            break;
        case ST_CONNECTED:
            eventType = "Connected";
            break;
        case ST_BECAMEPLAYER: // TODO implement
            eventType = "BecamePlayer";
            break;
        case ST_BECAMESPECTATOR: // TODO implement
            eventType = "BecameSpectator";
            break;
    }

    event = strcat("\"GameID\":", ftos(this.GameID), "\"GameTime\":", ftos(gameTime), ", \"EventType\": \"", eventType, "\", \"Player\": {");
    event = strcat(event, "\"TF_ID\":", ftos(player.tf_id), "\"Name\": \"", player.netname, "\", \"Team\":", ftos(player.team_no));
    event = strcat(event, ", \"Class\":", ftos(player.playerclass), "}");

    this.PostData(endpoint, event);
}

void FO_StatTracker :: GameStateChange(float stateType)
{
    if (stateType != ST_GAMESTART && this.GameID == 0)
        return;

    string endpoint = "GameStateChange";
    string event = "";
    string serverName = "";
    serverName = infokey(world, "hostname");
    string eventType = "";
    float gameTime = 0;

    if (serverName == "")
    {
        serverName = "unnamed";
    }

    switch (stateType)
    {
        case ST_GAMESTART:
            this.GameStartReqID = this.RequestID;
            eventType = "GameStart";
            event = strcat("\"GameID\": ", ftos(this.GameID), ", \"ServerName\": \"", serverName, "\", \"GameTime\": ", ftos(gameTime), ",");
            event = strcat(event, "\"EventType\": \"", eventType, "\", \"Map\": \"", mapname, "\", \"Initiator\": \"world\"");
            // send player info too
            entity p;
            float loopCount = 0;
            event = strcat(event, ", \"Players\": [");
            p = find(world, ::classname, "player");
            while(p)
            {
                if (loopCount > 0)
                {
                    event = strcat(event, ", ");
                }
                loopCount = loopCount + 1;

                event = strcat(event, "\"TF_ID\":", ftos(p.tf_id), "{\"Name\":\"", p.netname, "\", \"Team\":", ftos(p.team_no), ", \"Class\":", ftos(p.playerclass), "}");
                p = find(p, ::classname, "player");
            }
            event = strcat(event, "]");

            // specs
            loopCount = 0;
            event = strcat(event, ", \"Spectators\": [");
            p = find(world, ::classname, "observer");

            while(p)
            {
                if (loopCount > 0)
                {
                    event = strcat(event, ", ");
                }
                loopCount = loopCount + 1;

                event = strcat(event, "{\"Name\":\"", p.netname, "\", \"Team\":", ftos(p.team_no), ", \"Class\":", ftos(p.playerclass), "}");
                p = find(p, ::classname, "observer");
            }
            event = strcat(event, "]");

            this.PostData(endpoint, event);           
            break;
    }
}

void URI_Get_Callback(float reqid, float responsecode, string resourcebody)
{
    dprint(ftos(responsecode));
    dprint (strcat("\n", resourcebody));

    if (StatTracker.GameID == 0)
    {
        if (reqid == StatTracker.GameStartReqID)
            StatTracker.GameID = stof(resourcebody);
    }
}