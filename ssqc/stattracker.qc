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
    ST_BROADCAST,
    ST_GOTFLAG,
    ST_DROPPEDFLAG,
    ST_CAPTUREDFLAG,
    ST_SCOREUPDATE,
    ST_REVEALSPY,
    ST_DISARMDETPACK
};

string DMSGToString(float dmsg);
string WeaponToString(float weapon, float isGren);
float IsCritHit(float weapon, float damage);

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
// TODO list of stuff
// in game stats
duelmode needs gamestart maybe?
t_damage calls
t_radiusdamage calls
quad round start and end
dismantle sentries and dispensers
became player
became spectator
bundle shoot json messages
dmsg_flame and dmsg_napalm, DMSG_INCENDIARYL

// FIXME
chat log? can't intercept bprints correctly because i'm dumb

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
    virtual void(entity player) Suicide;
    virtual void(float tfid, string weaponType, float shotID, string deathType) ShootPost;
    virtual void(string endpoint, string data) PostData;
    virtual void() ScoreUpdate;

    virtual string() GameString;
    virtual string(entity player) PlayerString;
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

void FO_StatTracker :: ShootPost(float tfid, string weaponType, float shotID, string deathType)
{
    string endpoint = "Shoot";
    string event;
    
    event = strcat(this.GameString(), ", \"TF_ID\":", ftos(tfid), ", \"WeaponType\": \"", weaponType, "\", \"Shot_ID\":", ftos(shotID));
    event = strcat(event, ", \"DeathType\": \"", deathType, "\"");

    this.PostData(endpoint, event);
}

void FO_StatTracker :: Suicide(entity player)
{
    float shotID = player.shot_id + 1;
    player.shot_id = shotID;
    string deathType = DMSGToString(DMSG_SUICIDE);
    string weaponType = "";

    this.ShootPost(player.tf_id, weaponType, shotID, deathType);
}

float FO_StatTracker :: Shoot(entity attacker, float weaponTypef, float isGren)
{
    float shotID = attacker.shot_id + 1;
    attacker.shot_id = shotID;
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
    
    this.ShootPost(attacker.tf_id, weaponType, shotID, deathType);

    return shotID;
}

// damage done, shot hit, killed
void FO_StatTracker :: Damage(entity targ, entity inflictor, entity attacker, float damage)
{
    dprint(strcat("deathtype: ", targ.deathtype, "\n"));
    /*if (this.GameID == 0)
        return;*/
    string endpoint = "Damage";
    float isCrit = IsCritHit(inflictor.weapon, damage); // direct/full damage
    float shotID = inflictor.shot_id; // player or missile
    float killed = (targ.health <= 0) ? 1 : 0;
    float deathtypef = (inflictor.weapon) ? inflictor.weapon : deathmsg; // should probably just use deathmsg all the time...
    float tfid = attacker.tf_id;
    float pc = attacker.playerclass;
    float hadFlag = FALSE;
    entity te;
    te = find(world, ::classname, "item_tfgoal");
    while (te) {
        if (te.owner == targ) {
            hadFlag = TRUE;
        }
        te = find(te, ::classname, "item_tfgoal");
    }

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
    event = strcat(this.GameString(), ", \"Attacker\": ", this.PlayerString(attacker), ", \"Target\": ", this.PlayerString(targ));
    event = strcat(event, ", \"WeaponType\": \"", weaponType, "\", \"Damage\":", ftos(damage), ", \"Shot_ID\":", ftos(shotID));
    event = strcat(event, ", \"VHeight\":", ftos(vheight), ", \"Killed\":", ftos(killed));
    event = strcat(event, ", \"DeathType\": \"", deathType, "\", \"HadFlag\":", ftos(hadFlag));

    this.PostData(endpoint, event);
}

void FO_StatTracker :: PlayerAction(float action, entity targ, entity attacker)
{
    string endpoint = "PlayerAction";
    string event = "";
    string actionString = "";

    switch (action)
    {
        case ST_REVEALSPY:
            actionString = "ST_REVEALSPY";
            break;
        case ST_DISARMDETPACK:
            actionString = "ST_DISARMDETPACK";
            break;
    }

    event = strcat(this.GameString(), ", \"Action\": \"", actionString, "\", \"Attacker\": ", this.PlayerString(attacker), ", \"Target\":", this.PlayerString(targ));
    this.PostData(endpoint, event);
}

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
            eventType = "ST_CHANGENAME";
            break;
        case ST_CHANGETEAM:
            eventType = "ST_CHANGETEAM";
            break;
        case ST_CHANGECLASS:
            eventType = "ST_CHANGECLASS";
            break;
        case ST_DISCONNECTED:
            eventType = "ST_DISCONNECTED";
            break;
        case ST_CONNECTED:
            eventType = "ST_CONNECTED";
            break;
        case ST_BECAMEPLAYER: // TODO implement
            eventType = "ST_BECAMEPLAYER";
            break;
        case ST_BECAMESPECTATOR: // TODO implement
            eventType = "ST_BECAMESPECTATOR";
            break;
        case ST_GOTFLAG:
            eventType = "ST_GOTFLAG";
            break;
        case ST_DROPPEDFLAG:
            eventType = "ST_DROPPEDFLAG";
            break;
        case ST_CAPTUREDFLAG:
            eventType = "ST_CAPTUREDFLAG";
            this.ScoreUpdate();
            break;
    }

    event = strcat(this.GameString(), ", \"EventType\": \"", eventType, "\", \"Player\": ", this.PlayerString(player));

    this.PostData(endpoint, event);
}

void FO_StatTracker :: ScoreUpdate()
{
    string endpoint = "ScoreUpdate";
    string event = "";

    event = strcat(this.GameString(), ", \"TeamOne\":", ftos(team1score));
    event = strcat(event, ", \"TeamTwo\":", ftos(team2score), "\"TeamThree\":", ftos(team3score), "\"TeamFour\":", ftos(team4score));
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
            eventType = "ST_GAMESTART";
            break;
        case ST_GAMEEND:
            eventType = "ST_GAMEEND";
            break;
    }

    string currmap;
    currmap = strtrim(mapname);
    event = strcat(this.GameString(), ", \"ServerName\": \"", serverName);
    event = strcat(event, ", \"EventType\": \"", eventType, "\", \"Map\": \"", currmap, "\", \"Initiator\": \"world\"");
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

        event = strcat(event, this.PlayerString(p));
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

        event = strcat(event, this.PlayerString(p));
        p = find(p, ::classname, "observer");
    }
    event = strcat(event, "]");

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

// generate common strings
string FO_StatTracker :: GameString()
{
    return strcat("\"GameID\": ", ftos(this.GameID), ", \"GameTime\": ", ftos(this.GameTime));
}

string FO_StatTracker :: PlayerString(entity p)
{
    string event;
    string name = (p.netname != "") ? p.netname : p.classname;
    event = strcat("{\"TF_ID\":", ftos(p.tf_id), ", \"Name\":\"", name, "\", \"Team\":", ftos(p.team_no));
    event = strcat(event, ", \"Class\":", ftos(p.playerclass), "}");
    return event;
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