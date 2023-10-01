local soundBank =      {
  id = "muse_expansion_empire",
  cellNamePatterns = {
    'Caldera',
    'Ebonheart',
    'Ebon Tower',
    'Pelagiad',
    'Seyda Neen',
    'Moonmoth',
    'Darius',
    'Firemoth',
    'Frostmoth',
    'Buckmoth',
    'Hawkmoth',
    'Wolverine Hall',
    'Raven Rock'
  },
  cellNamePatternsExclude = {
    'Mage\'s Guild',
    'Fighter\'s Guild',
    'Guild of Mages',
    'Guild of Fighters'
  },
  tracks = {
    {
      path="Music/MS/cell/ImperialCity/Beacon of Cyrodiil.mp3",
      length=220
    }
  },
  combatTracks = {
    {
      path="Music/MS/combat/Empire/combat1.mp3",
      length=79
    },
    {
      path="Music/MS/combat/Empire/combat2.mp3",
      length=68
    },
    {
      path="Music/MS/combat/Empire/combat3.mp3",
      length=89
    }
  }
}

return soundBank
