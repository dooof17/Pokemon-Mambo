#===========================================
#    Simple Encounter List Window by raZ   #
#                                          #
#    Credits:                              #
#         - raZ --> original script        #
#         - Nuri Yuri, Vendily --> additions for v1.2 #
#         - Zaffre --> icon edits + NatDex iter. #
#         - ThatWelshOne_ --> v18 update   #
#         - Xaveriux --> GSC version       #
#===========================================
#    To use it, call the following         #
#    function:                             #
#                                          #
#    pbEncounterListUI                     #
#===========================================

  # Currently known issues:
  # 1. Common crash if not starting from a new save.
  
  # Method that checks whether a specific form has been seen by the player
  def pbFormSeen?(species,form)
    return $Trainer.formseen[species][0][form] || 
      $Trainer.formseen[species][1][form]
  end
  
  # Method that checks whether a specific form is owned by the player
  def pbFormOwned?(species,form)
    return $Trainer.formowned[species][0][form] || 
      $Trainer.formowned[species][1][form]
  end


#===========================================
# Encounter list UI
#===========================================

# Folder that contains the files
ENC_FOLDER = "Graphics/Pictures/Encounters/"

# This is the name of a graphic in your Graphics/Pictures folder that changes the look of the UI
# If the graphic does not exist, you will get an error
WINDOWSKIN = "bg.png"

# This array allows you to overwrite the names of your encounter types if you want them to be more logical
# E.g. "Surfing" instead of "Water"
# By default, the method uses the encounter type names in the EncounterTypes module
NAMES = ["Grass", "Cave", "Surfing", "Rock Smash", "Fishing (Old Rod)",
      "Fishing (Good Rod)", "Fishing (Super Rod)", "Headbutt (Low)",
      "Headbutt (High)", "Grass (morning)", "Grass (day)", "Grass (night)",
      "Bug Contest"]
#NAMES = nil

# Controls whether Deerling's seasonal form is used for the UI
DEERLING = true

class EncounterListUI_withforms
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @encarray1 = []
    @encarray2 = []
    @index = 0
    @encdata = load_data("Data/encounters.dat")
    @mapid = $game_map.map_id
  end
 
  def pbStartMenu
    getEncData
    if !File.file?(ENC_FOLDER + WINDOWSKIN)
      raise _INTL("You are missing the graphic for this UI. Make sure the image is in your Graphics/Pictures folder and that it is named appropriately.")
    end
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap(ENC_FOLDER + WINDOWSKIN)
    @sprites["background"].x = 0
    @sprites["background"].y = 0
    @sprites["locwindow"] = Window_AdvancedTextPokemon.new("")
    @sprites["locwindow"].viewport = @viewport
    @sprites["locwindow"].width = 320
    @sprites["locwindow"].height = 288
    @sprites["locwindow"].x = (Graphics.width - @sprites["locwindow"].width)/2
    @sprites["locwindow"].y = (Graphics.height - @sprites["locwindow"].height)/2
    @sprites["locwindow"].windowskin = nil
    # Width value
    @w = 18
    # Height value
    @h = 204
    if !@num_enc
      loctext = _INTL("<ac>{1}:</ac>", $game_map.name)
      loctext += _INTL("-----------------------------")
      loctext += sprintf("<ac>This area has no encounters!</ac>")
      @sprites["locwindow"].setText(loctext)
      waitForExit
    else
      if !NAMES.nil? # If NAMES is not nil
        @name = NAMES[@type[@index]] # Pull string from NAMES array
      else
        @name = [EncounterTypes::Names].flatten[@type[@index]] # Otherwise, use default names
      end
      loctext = _INTL("<ac>{1}:</ac>", $game_map.name)
      loctext += _INTL("<ac>{1}</ac>",@name)
      loctext += _INTL("-----------------------------")
      i = 0
      @encarray2.each do |specie| # Loops over internal IDs of encounters on current map     
        fSpecies = pbGetSpeciesFromFSpecies(specie) # Array of internal ID of base form and form ID of specie
        if !pbFormSeen?(fSpecies[0],fSpecies[1]) && !pbFormOwned?(fSpecies[0],fSpecies[1])
          @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(0,@viewport)
        elsif !pbFormOwned?(fSpecies[0],fSpecies[1])
          @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(fSpecies[0],@viewport)
          @sprites["icon_#{i}"].pbSetParams(fSpecies[0],0,fSpecies[1],false)
          @sprites["icon_#{i}"].tone = Tone.new(0,0,0,255)
        else
          @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(fSpecies[0],@viewport)
          @sprites["icon_#{i}"].pbSetParams(fSpecies[0],0,fSpecies[1],false)
        end
        @sprites["icon_#{i}"].x = @w + 50*(i%6)
        @sprites["icon_#{i}"].y = @h + (i/6)*32
        i +=1         
      end
      loctext += sprintf("<ac>Total encounters: %s</ac>",@encarray2.length)
      @sprites["locwindow"].setText(loctext)
      @sprites["rightarrow"] = AnimatedSprite.new(ENC_FOLDER + "next_right",2,10,22,6,@viewport)
      @sprites["rightarrow"].x = Graphics.width - @sprites["rightarrow"].bitmap.width
      @sprites["rightarrow"].y = 226
      @sprites["rightarrow"].visible = false
      @sprites["rightarrow"].play
      @sprites["leftarrow"] = AnimatedSprite.new(ENC_FOLDER + "next_left",2,10,22,6,@viewport)
      @sprites["leftarrow"].x = 0
      @sprites["leftarrow"].y = 226
      @sprites["leftarrow"].visible = false
      @sprites["leftarrow"].play
      main1
    end
  end
 
  def pbListOfEncounters(encounter) # This method is from Nuri Yuri
    return [] unless encounter
   
    encable = encounter.compact # Remove nils
    #encable.map! { |enc_list| enc_list.map { |enc| enc[0] } }
    encable.map! {|enc| enc[0]} # Pull first element from each array
    encable.flatten! # Transform array of arrays into array
    encable.uniq! # Prevent duplication
   
    return encable
  end
 
  def getEncData
    if @encdata.is_a?(Hash) && @encdata[@mapid]
      enc = @encdata[@mapid][1]
      @num_enc = enc.compact.length # Number of defined encounter types on current map
      @type = (0...enc.length).reject {|i| enc[i].nil? } # Array indices of non-nil array elements
      @first = enc.index(enc.find { |i| !i.nil? } || false) # From Yuri to get index of first non-nil array element
      enctypes = enc[@type[@index]]
      @encarray1 = pbListOfEncounters(enctypes)
      temp = []
      @encarray1.each_with_index do |s,i| # Funky method for grouping forms with their base forms
        if (isConst?(s,PBSpecies,:DEERLING) || 
          isConst?(s,PBSpecies,:SAWSBUCK)) && DEERLING
          @encarray1[i] = pbGetFSpeciesFromForm(s,pbGetSeason)
        end
        fSpecies = pbGetSpeciesFromFSpecies(s)
        temp.push(fSpecies[0] + fSpecies[1]*0.001)
      end
      temp_sort = temp.sort
      id = temp_sort.map{|s| temp.index(s)}
      @encarray2 = []
      for i in 0..@encarray1.length-1
        @encarray2[i] = @encarray1[id[i]]
      end
    else
      @encarray2 = [7]
    end
  end
  
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end
  
  def pbShift
    for i in 0...@encarray2.length
      @sprites["icon_#{i}"].dispose
    end
  end
  
  def main1
    loop do
      Graphics.update
      Input.update
      pbUpdate
        if @first == @type[@index] && @num_enc >1 # If first page and there are more pages
          @sprites["leftarrow"].visible=false
          @sprites["rightarrow"].visible=true
        elsif @index == @type.length-1 && @num_enc >1 # If last page and there is more than one page
          @sprites["leftarrow"].visible=true
          @sprites["rightarrow"].visible=false
        end
        if Input.trigger?(Input::RIGHT) && @num_enc >1 && @index< @num_enc-1
          pbPlayCursorSE
          @index += 1
          pbShift # Dispose sprites
          main2
          @sprites["leftarrow"].visible=true
          @sprites["rightarrow"].visible=true
        elsif Input.trigger?(Input::LEFT) && @num_enc >1 && @index !=0
          pbPlayCursorSE
          @index -= 1
          pbShift # Dispose sprites
          main2
          @sprites["leftarrow"].visible=true
          @sprites["rightarrow"].visible=true
        elsif Input.trigger?(Input::C) || Input.trigger?(Input::B)
          pbPlayCloseMenuSE
          break
        end
      end
    dispose
  end
 
  def main2
    getEncData
    if !NAMES.nil?
      @name = NAMES[@type[@index]]
    else
      @name = [EncounterTypes::Names].flatten[@type[@index]]
    end
    loctext = _INTL("<ac>{1}:</ac>", $game_map.name)
    loctext += _INTL("<ac>{1}</ac>",@name)
    loctext += _INTL("-----------------------------")
    i = 0
    @encarray2.each do |specie| # Loops over internal IDs of encounters on current map     
      fSpecies = pbGetSpeciesFromFSpecies(specie) # Array of internal ID of base form and form ID of specie
      if !pbFormSeen?(fSpecies[0],fSpecies[1]) && !pbFormOwned?(fSpecies[0],fSpecies[1])
        @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(0,@viewport)
      elsif !pbFormOwned?(fSpecies[0],fSpecies[1])
        @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(fSpecies[0],@viewport)
        @sprites["icon_#{i}"].pbSetParams(fSpecies[0],0,fSpecies[1],false)
        @sprites["icon_#{i}"].tone = Tone.new(0, 0, 0, 255)
      else
        @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(fSpecies[0],@viewport)
        @sprites["icon_#{i}"].pbSetParams(fSpecies[0],0,fSpecies[1],false)
      end
      @sprites["icon_#{i}"].x = @w + 50*(i%6)
      @sprites["icon_#{i}"].y = @h + (i/6)*32
      i +=1         
    end
    loctext += sprintf("<ac>Total encounters: %s</ac>",@encarray2.length)
    @sprites["locwindow"].setText(loctext)
  end
  
  def waitForExit
    loop do
      Graphics.update
      Input.update
      if Input.trigger?(Input::C) || Input.trigger?(Input::B)
        pbPlayCloseMenuSE
		Input.update
        break
      end
    end
    dispose
  end
  
  def dispose
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

###############################################
### Cleaner way of calling the class method ###
###############################################

  def pbEncounterListUI
    EncounterListUI_withforms.new.pbStartMenu
  end