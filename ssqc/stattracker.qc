enum
{
    ST_GAMESTART,
    ST_GAMEEND,
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
suicides
// holding concs and non damage grens
// duelmode needs gamestart maybe?
disarm detpacks
reveal spies
t_damage calls
quad round start and end

// chat log?

// TODO bundle shoot json messages

*/

class FO_StatTracker
{
    float RequestID;
    string URL;
    float GameID;
    float GameStartReqID; // used to track request id of game init, so we can set gameid
    float GameStartTime;
    float GameTime;

    void FO_StatTracker; // constructor
    virtual void() IncrementGameTime;
    virtual void(float stateType) GameStateChange;
    virtual void(float stateType, entity player) PlayerStateChange;
    /*virtual void(float stateType, float msglvl, string s, optional string s2, 
        optional string s3, optional string s4, optional string s5, optional string s6) BroadcastMessage;*/
    virtual void(entity targ, entity inflictor, entity attacker, float damage) Damage;
    virtual float(entity attacker, float weaponTypef, float isGren) Shoot;
    virtual void(string endpoint, string data) PostData;
};

FO_StatTracker StatTracker; // global
void FO_StatTracker :: FO_StatTracker(void)
{
    RequestID = 0;
    URL = "http://localhost:5000/api/SSQCStats";
    GameID = 0;
    GameStartReqID = 0;
    GameTime = 0;
}

void FO_StatTracker :: IncrementGameTime()
{
    if (clanbattle)
    {
        if (!this.GameStartTime)
        {
            if (cb_prematch)
            {
                return;
            }
            else
            {
                this.GameStartTime = time;
            }
        }
    }
    else if (!this.GameStartTime)
    {
        this.GameStartTime = time;
    }

    this.GameTime = (time - GameStartTime);
}

void FO_StatTracker :: PostData(string endpoint, string data)
{
    string url = strcat(this.URL, "/", endpoint);
    data = strcat("{", data, "}");
    
    //uri_post(url, this.RequestID, "application/json", data);

    this.RequestID = this.RequestID + 1;
    dprint(strcat(url,"\n"));
    dprint(strcat(data,"\n"));
}

string WeaponToString(float weapon, float isGren);
string DMSGToString(float dmsg);
float FO_StatTracker :: Shoot(entity attacker, float weaponTypef, float isGren)
{
    float shotID = attacker.shot_id + 1;
    attacker.shot_id = shotID;
    string endpoint = "Shoot";
    string weaponType = "None";
    string deathType = "None";

    if (attacker.classname == "building_sentrygun" || attacker.classname == "building_dispenser")
    {
        deathType = DMSGToString(weaponTypef);
    }
    else
    {
        weaponType = WeaponToString(weaponTypef, isGren);
    }
    
    string event;
    
    event = strcat("\"TF_ID\":", ftos(attacker.tf_id), ", \"WeaponType\": \"", weaponType, "\", \"Shot_ID\":", ftos(attacker.shot_id), ", \"GameTime\":", ftos(this.GameTime));
    event = strcat(event, ", \"DeathType\": \"", deathType, "\", \"GameID\":", ftos(this.GameID));

    this.PostData(endpoint, event);

    return shotID;
}

float IsCritHit(float weapon, float damage);

// damage done, shot hit, killed
void FO_StatTracker :: Damage(entity targ, entity inflictor, entity attacker, float damage)
{
    /*if (this.GameID == 0)
        return;*/
    string endpoint = "Damage";
    float isCrit = IsCritHit(inflictor.weapon, damage); // direct/full damage
    float shotID = inflictor.shot_id; // player or missile
    float killed = (targ.health <= 0) ? 1 : 0;
    float deathtypef = inflictor.weapon;
    float tfid = attacker.tf_id;
    float pc = attacker.playerclass;

    if (attacker.classname == "building_sentrygun" || inflictor.classname == "building_dispenser"
        || inflictor.classname == "building_sentrygun")
    {
        tfid = (attacker.real_owner != 0) ? attacker.real_owner.tf_id : inflictor.real_owner.tf_id; // sentry is attacker mostly, inflictor if blowing up etc
        pc = (attacker.real_owner != 0) ? attacker.real_owner.playerclass : inflictor.real_owner.playerclass;

        // sometimes deathmsg not set, explicitly set deathtypef
        switch (inflictor.classname)
        {
            case "building_dispenser":
                deathtypef = DMSG_DISPENSER_EXPLODE;
                break;
            default:
                deathtypef = deathmsg;
        }
        
    }

    string deathType = DMSGToString(deathtypef);
    float isGren = IsGrenNotWeapon(inflictor);
    string weaponType = WeaponToString(inflictor.weapontype, isGren);

    // if not in water
    // calc midheight distance between targ origin and ground
    float vheight = 0;
    if (targ.waterlevel == 0)
    {
        vector end;
        end = targ.origin;
        end_z = end_z - 10000;
        traceline(targ.origin, end, MOVE_NOMONSTERS, targ);
        vheight = vlen(targ.origin - trace_endpos); // vertical height (midairs)
        vheight = vheight - 24; // feet
    }

    string event;
    event = strcat("\"Attacker\": {\"TF_ID\": ", ftos(tfid), ", \"ClassName\": \"", attacker.classname, "\", \"Team\":", ftos(attacker.team_no), ", \"Class\":", ftos(pc));
    event = strcat(event, "}, \"Target\": {\"TF_ID\": ", ftos(targ.tf_id), ", \"ClassName\": \"", targ.classname, "\", \"Team\":", ftos(targ.team_no), ", \"Class\":");
    event = strcat(event, ftos(targ.playerclass), "}, \"WeaponType\": \"", weaponType, "\", \"Damage\":", ftos(damage), ", \"Shot_ID\":", ftos(shotID));
    event = strcat(event, ", \"VHeight\":", ftos(vheight), ", \"Killed\":", ftos(killed), ", \"GameTime:\":", ftos(this.GameTime));
    event = strcat(event, ", \"GameID\": ", ftos(this.GameID), ", \"DeathType\": \"", deathType, "\"");

    this.PostData(endpoint, event);
}


/*
void FO_StatTracker :: BroadcastMessage(float stateType, float msglvl, string s, optional string s2, 
        optional string s3, optional string s4, optional string s5, optional string s6)
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
*/
void FO_StatTracker :: PlayerStateChange(float stateType, entity player)
{
    /*if (this.GameID == 0)
        return;*/

    string endpoint = "PlayerStateChange";
    string event = "";
    string eventType = "";

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

    event = strcat("\"GameID\":", ftos(this.GameID), ", \"GameTime\":", ftos(this.GameTime), ", \"EventType\": \"", eventType, "\", \"Player\": {");
    event = strcat(event, "\"TF_ID\":", ftos(player.tf_id), ", \"Name\": \"", player.netname, "\", \"Team\":", ftos(player.team_no));
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

    if (serverName == "")
    {
        serverName = "unnamed";
    }

    switch (stateType)
    {
        case ST_GAMESTART:
            this.GameStartTime = time;
            this.GameStartReqID = this.RequestID;
            eventType = "GameStart";
            break;
        case ST_GAMEEND:
            eventType = "GameEnd";
            break;
    }

    string currmap;
    currmap = strtrim(mapname);
    event = strcat("\"GameID\": ", ftos(this.GameID), ", \"ServerName\": \"", serverName, "\", \"GameTime\": ", ftos(this.GameTime), ",");
    event = strcat(event, "\"EventType\": \"", eventType, "\", \"Map\": \"", currmap, "\", \"Initiator\": \"world\"");
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

        event = strcat(event, "{\"TF_ID\":", ftos(p.tf_id), ", \"Name\":\"", p.netname, "\", \"Team\":", ftos(p.team_no));
        event = strcat(event, ", \"Class\":", ftos(p.playerclass), "}");
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

/*
void bprint(float msglvl, string s, optional string s2, optional string s3, optional string s4, optional string s5, optional string s6, optional string s7) 
{

    string msg = "";
    msg = strcat(s, s2, s3, s4, s5, s6, s7);
    dprint(msg);


    //StatTracker.BroadcastMessage(ST_BROADCAST, msglvl, s, s2, s3, s4, s5, six);
    bprint_engine(msglvl, s, s2, s3, s4, s5, s6, s7);
}*/