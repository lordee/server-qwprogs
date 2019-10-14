string ClassToString(float num)
{
    if (num == 1) return "Scout";
    if (num == 2) return "Sniper";
    if (num == 3) return "Soldier";
    if (num == 4) return "Demoman";
    if (num == 5) return "Medic";
    if (num == 6) return "HWGuy";
    if (num == 7) return "Pyro";
    if (num == 8) return "Spy";
    if (num == 9) return "Engineer";
    if (num == 11) return "Civilian";
    if (num == 13) return "Sentry Gun";
    if (num == 14) return "Goal Item";
    return "";
}

string TeamToString(float num)
{
    if (num == 1) return "Blue";
    if (num == 2) return "Red";
    if (num == 3) return "Yellow";
    if (num == 4) return "Green";
    return " ";
}

// TODO laser grens
string WeaponToString(float weapon, float isGren)
{
    string msg = "";
    if (isGren)
    {
        switch (weapon)
        {
            case GR_TYPE_NORMAL:
                msg = "GR_TYPE_NORMAL";
            break;
            case GR_TYPE_CONCUSSION:
                msg = "GR_TYPE_CONCUSSION";
                break;
            case GR_TYPE_NAIL:
                msg = "GR_TYPE_NAIL";
                // laser gren???
                break;
            case GR_TYPE_MIRV:
                msg = "GR_TYPE_MIRV";
                break;
            case GR_TYPE_NAPALM:
                msg = "GR_TYPE_NAPALM";
                break;
            case GR_TYPE_FLARE:
                msg = "GR_TYPE_FLARE";
                break;
            case GR_TYPE_GAS:
                msg = "GR_TYPE_GAS";
                break;
            case GR_TYPE_EMP:
                msg = "GR_TYPE_EMP";
                break;
            case GR_TYPE_FLASH:
                msg = "GR_TYPE_FLASH";
                break;
            case GR_TYPE_CALTROP:
                msg = "GR_TYPE_CALTROP";
                break;
            default:
            msg = strcat("NOT FOUND: ", ftos(weapon));
        }
    }
    else
    {
        switch (weapon)
        {
            case WEAP_AXE:
                msg = "WEAP_AXE";
                break;
            case WEAP_SPANNER:
                msg = "WEAP_SPANNER";
                break;
            case WEAP_SHOTGUN:
                msg = "WEAP_SHOTGUN";
                break;
            case WEAP_SUPER_SHOTGUN:
                msg = "WEAP_SUPER_SHOTGUN";
                break;
            case WEAP_NAILGUN:
                msg = "WEAP_NAILGUN";
                break;
            case WEAP_SUPER_NAILGUN:
                msg = "WEAP_SUPER_NAILGUN";
                break;
            case WEAP_GRENADE_LAUNCHER:
                msg = "WEAP_GRENADE_LAUNCHER";
                break;
            case WEAP_ROCKET_LAUNCHER:
                msg = "WEAP_ROCKET_LAUNCHER";
                break;
            case WEAP_LIGHTNING:
                msg = "WEAP_LIGHTNING";
                break;
            case WEAP_SNIPER_RIFLE:
                msg = "WEAP_SNIPER_RIFLE";
                break;
            case WEAP_AUTO_RIFLE:
                msg = "WEAP_AUTO_RIFLE";
                break;
            case WEAP_ASSAULT_CANNON:
                msg = "WEAP_ASSAULT_CANNON";
                break;
            case WEAP_FLAMETHROWER:
                msg = "WEAP_FLAMETHROWER";
                break;
            case WEAP_INCENDIARY:
                msg = "WEAP_INCENDIARY";
                break;
            case WEAP_MEDIKIT:
                msg = "WEAP_MEDIKIT";
                break;
            case WEAP_TRANQ:
                msg = "WEAP_TRANQ";
                break;
            case WEAP_LASER:
                msg = "WEAP_LASER";
                break;
            case WEAP_HOOK:
                msg = "WEAP_HOOK";
                break;
            case WEAP_DETPACK:
                msg = "WEAP_DETPACK";
                break;
            default:
                msg = strcat("NOT FOUND: ", ftos(weapon));
        }
    }
    
    return msg;
}

string DMSGToString(float dmsg)
{
    string msg = "";
    switch (dmsg)
    {
        case DMSG_SHOTGUN:
            msg = "DMSG_SHOTGUN";
            break;
        case DMSG_SSHOTGUN:
            msg = "DMSG_SSHOTGUN";
            break;
        case DMSG_NAILGUN:
            msg = "DMSG_NAILGUN";
            break;
        case DMSG_SNAILGUN:
            msg = "DMSG_SNAILGUN";
            break;
        case DMSG_GRENADEL:
            msg = "DMSG_GRENADEL";
            break;
        case DMSG_ROCKETL:
            msg = "DMSG_ROCKETL";
            break;
        case DMSG_LIGHTNING:
            msg = "DMSG_LIGHTNING";
            break;
        case DMSG_GREN_HAND:
            msg = "DMSG_GREN_HAND";
            break;
        case DMSG_GREN_NAIL:
            msg = "DMSG_GREN_NAIL";
            break;
        case DMSG_GREN_MIRV:
            msg = "DMSG_GREN_MIRV";
            break;
        case DMSG_GREN_PIPE:
            msg = "DMSG_GREN_PIPE";
            break;
        case DMSG_DETPACK:
            msg = "DMSG_DETPACK";
            break;
        case DMSG_BIOWEAPON:
            msg = "DMSG_BIOWEAPON";
            break;
        case DMSG_BIOWEAPON_ATT:
            msg = "DMSG_BIOWEAPON_ATT";
            break;
        case DMSG_FLAME:
            msg = "DMSG_FLAME";
            break;
        case DMSG_DETPACK_DIS:
            msg = "DMSG_DETPACK_DIS";
            break;
        case DMSG_AXE:
            msg = "DMSG_AXE";
            break;
        case DMSG_SNIPERRIFLE:
            msg = "DMSG_SNIPERRIFLE";
            break;
        case DMSG_AUTORIFLE:
            msg = "DMSG_AUTORIFLE";
            break;
        case DMSG_ASSAULTCANNON:
            msg = "DMSG_ASSAULTCANNON";
            break;
        case DMSG_HOOK:
            msg = "DMSG_HOOK";
            break;
        case DMSG_BACKSTAB:
            msg = "DMSG_BACKSTAB";
            break;
        case DMSG_MEDIKIT:
            msg = "DMSG_MEDIKIT";
            break;
        case DMSG_GREN_GAS:
            msg = "DMSG_GREN_GAS";
            break;
        case DMSG_TRANQ:
            msg = "DMSG_TRANQ";
            break;
        case DMSG_LASERBOLT:
            msg = "DMSG_LASERBOLT";
            break;
        case DMSG_SENTRYGUN_BULLET:
            msg = "DMSG_SENTRYGUN_BULLET";
            break;
        case DMSG_SNIPERLEGSHOT:
            msg = "DMSG_SNIPERLEGSHOT";
            break;
        case DMSG_SNIPERHEADSHOT:
            msg = "DMSG_SNIPERHEADSHOT";
            break;
        case DMSG_GREN_EMP:
            msg = "DMSG_GREN_EMP";
            break;
        case DMSG_GREN_EMP_AMMO:
            msg = "DMSG_GREN_EMP_AMMO";
            break;
        case DMSG_SPANNER:
            msg = "DMSG_SPANNER";
            break;
        case DMSG_INCENDIARY:
            msg = "DMSG_INCENDIARY";
            break;
        case DMSG_SENTRYGUN_ROCKET:
            msg = "DMSG_SENTRYGUN_ROCKET";
            break;
        case DMSG_GREN_FLASH:
            msg = "DMSG_GREN_FLASH";
            break;
        case DMSG_TRIGGER:
            msg = "DMSG_TRIGGER";
            break;
        case DMSG_TEAMKILL:
            msg = "DMSG_TEAMKILL";
            break;
        case DMSG_SENTRYGUN_EXPLODE:
            msg = "DMSG_SENTRYGUN_EXPLODE";
            break;
        case DMSG_DISPENSER_EXPLODE:
            msg = "DMSG_DISPENSER_EXPLODE";
            break;
        case DMSG_GREN_PIPE_AIR:
            msg = "DMSG_GREN_PIPE_AIR";
            break;
        case DMSG_GREN_CALTROP:
            msg = "DMSG_GREN_CALTROP";
            break;
        case DMSG_SUICIDE:
            msg = "DMSG_SUICIDE";
            break;
        case DMSG_FALLING:
            msg = "DMSG_FALLING";
            break;
        case DMSG_DROWN:
            msg = "DMSG_DROWN";
            break;
        case DMSG_SLIME:
            msg = "DMSG_SLIME";
            break;
        case DMSG_LAVA:
            msg = "DMSG_LAVA";
            break;
        case DMSG_EXPLODEBOX:
            msg = "DMSG_EXPLODEBOX";
            break;
        case DMSG_SQUISHED:
            msg = "DMSG_SQUISHED";
            break;
        case DMSG_TRAPSHOOTER:
            msg = "DMSG_TRAPSHOOTER";
            break;
        case DMSG_FIREBALL:
            msg = "DMSG_FIREBALL";
            break;
        case DMSG_LASER:
            msg = "DMSG_LASER";
            break;
        case DMSG_INCENDIARYL:
            msg = "DMSG_INCENDIARYL";
            break;
        case DMSG_ITEMGOAL:
            msg = "DMSG_ITEMGOAL";
            break;
        default:
            msg = strcat("NOT FOUND: ", ftos(dmsg));
    }
    return msg;
}