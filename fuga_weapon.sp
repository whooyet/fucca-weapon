#include <tf2items>
#include <tf2_stocks>

new String:PrimaryConfig[120];

public Plugin myinfo = 
{
	name = "Simple Custom Weapon",
	author = "뿌까",
	description = "하하하하",
	version = "1.0",
	url = "x"
};

public OnPluginStart()
{
	BuildPath(Path_SM, PrimaryConfig, sizeof(PrimaryConfig), "configs/fuga_weapon.cfg");
	RegAdminCmd("sm_cw", aaaa, 0, "무기를 대여할 수 있는 명령어입니다.");
}

public Action:aaaa(client, args)
{
	new String:SearchWord[16], SearchValue;
	GetCmdArgString(SearchWord, sizeof(SearchWord));
	
	decl String:Classname[128], String:att[128], String:name[100], index, lv, qual, preserve, slot, ammo;
	new String:temp[256];
	
	new Handle:menu = CreateMenu(WeaponSelect);
	new Handle:DB = CreateKeyValues("weapon"); 
	
	SetMenuTitle(menu, "무기고르삼", client);
		
	FileToKeyValues(DB, PrimaryConfig);
	if(KvGotoFirstSubKey(DB))
	{
		do
		{
			KvGetSectionName(DB, name, sizeof(name));
			KvGetString(DB, "classname", Classname, sizeof(Classname));
			KvGetString(DB, "attribute", att, sizeof(att));
			
			slot = KvGetNum(DB, "slot", 0);
			preserve = KvGetNum(DB, "preserve", 1);
			index = KvGetNum(DB, "index", 0);
			lv = KvGetNum(DB, "level", 1);
			qual = KvGetNum(DB, "qual", 7);
			ammo = KvGetNum(DB, "ammo", -1);
			
			Format(temp, sizeof(temp), "%s*%d*%d*%d*%s*%d*%d*%d", Classname, index, lv, qual, att, preserve, slot, ammo);
			
			if(StrContains(name, SearchWord, false) > -1)
			{
				AddMenuItem(menu, temp, name);
				SearchValue++;
			}
		}
		while(KvGotoNextKey(DB));
		
		KvGoBack(DB);
	}
	
	if(!SearchValue)
	{
		PrintToChat(client, "\x03이름이 잘못되었거나 없는 이름입니다.");
		return Plugin_Handled;
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	KvRewind(DB);
	CloseHandle(DB);
	
	return Plugin_Handled;
}

public WeaponSelect(Handle:menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		decl String:info[256], String:aa[8][128];
		GetMenuItem(menu, select, info, sizeof(info));
		
		ExplodeString(info, "*", aa, 8, 128);
		SpawnWeapon(client, aa[0], StringToInt(aa[6]), StringToInt(aa[1]), StringToInt(aa[2]), StringToInt(aa[3]), aa[4], TF2_GetPlayerClass(client), StringToInt(aa[5]), StringToInt(aa[7]));
	}
	
	else if(action == MenuAction_End) CloseHandle(menu);
}

stock SpawnWeapon(client,String:name[],slot,index,level,qual,String:att[], TFClassType:classbased = TFClass_Unknown, use, ammo)
{
	new Flags;
	
	if(use == 1) Flags = OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES;
	else Flags = OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES;
	
	new Handle:newItem = TF2Items_CreateItem(Flags);

	
	if (newItem == INVALID_HANDLE)
		return -1;
	
	if (strcmp(name, "saxxy", false) != 0) Flags |= FORCE_GENERATION;
	
	if (StrEqual(name, "tf_weapon_shotgun", false)) strcopy(name, 64, "tf_weapon_shotgun_soldier");
	if (strcmp(name, "tf_weapon_shotgun_hwg", false) == 0 || strcmp(name, "tf_weapon_shotgun_pyro", false) == 0 || strcmp(name, "tf_weapon_shotgun_soldier", false) == 0)
	{
		switch (classbased)
		{
			case TFClass_Heavy: strcopy(name, 64, "tf_weapon_shotgun_hwg");
			case TFClass_Soldier: strcopy(name, 64, "tf_weapon_shotgun_soldier");
			case TFClass_Pyro: strcopy(name, 64, "tf_weapon_shotgun_pyro");
		}
	}
	
	TF2Items_SetClassname(newItem, name);
	TF2Items_SetItemIndex(newItem, index);
	TF2Items_SetLevel(newItem, level);
	TF2Items_SetQuality(newItem, qual);
	TF2Items_SetFlags(newItem, Flags);
	
	new String:atts[32][32]; 
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	
	if (count > 1)
	{
		TF2Items_SetNumAttributes(newItem, count/2);
		new i2 = 0;
		for (new i = 0;  i < count;  i+= 2)
		{
			TF2Items_SetAttribute(newItem, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(newItem, 0);
		
	TF2_RemoveWeaponSlot(client, slot);
	new entity = TF2Items_GiveNamedItem(client, newItem);
	SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	if(StrEqual(name,"tf_weapon_sapper"))
	{	
		SetEntProp(entity, Prop_Send, "m_iObjectType", 3);
		SetEntProp(entity, Prop_Data, "m_iSubType", 3);
	}
	
	EquipPlayerWeapon(client, entity);
	SetSpeshulAmmo(client, entity, ammo);

	CloneHandle(newItem);
	return entity;
}

stock SetSpeshulAmmo(client, weapon, newAmmo)
{
	if (!IsValidEntity(weapon)) return;
	new type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (type < 0 || type > 31) return;
	if(newAmmo != -1) SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, type);
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}