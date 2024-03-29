class Window_PokemonBag < Window_DrawableCommand
  attr_reader :pocket
  attr_accessor :sorting

  def initialize(bag,filterlist,pocket,x,y,width,height)
    @bag        = bag
    @filterlist = filterlist
    @pocket     = pocket
    @sorting = false
    @adapter = PokemonMartAdapter.new
    super(x,y,width,height)
    @selarrow  = AnimatedBitmap.new("Graphics/Pictures/Bag/cursor")
    @swaparrow = AnimatedBitmap.new("Graphics/Pictures/Bag/cursor_swap")
    self.windowskin = nil
    @row_height = 32
  end

  def dispose
    @swaparrow.dispose
    super
  end

  def pocket=(value)
    @pocket = value
    @item_max = (@filterlist) ? @filterlist[@pocket].length+1 : @bag.pockets[@pocket].length+1
    self.index = @bag.getChoice(@pocket)
  end

  def page_row_max; return PokemonBag_Scene::ITEMSVISIBLE; end
  def page_item_max; return PokemonBag_Scene::ITEMSVISIBLE; end

  def item
    return 0 if @filterlist && !@filterlist[@pocket][self.index]
    thispocket = @bag.pockets[@pocket]
    item = (@filterlist) ? thispocket[@filterlist[@pocket][self.index]] : thispocket[self.index]
    return (item) ? item[0] : 0
  end

  def itemCount
    return (@filterlist) ? @filterlist[@pocket].length+1 : @bag.pockets[@pocket].length+1
  end

  def itemRect(item)
    if item<0 || item>=@item_max || item<self.top_item-1 ||
       item>self.top_item+self.page_item_max
      return Rect.new(0,0,0,0)
    else
      cursor_width = (self.width-self.borderX-(@column_max-1)*@column_spacing) / @column_max
      x = item % @column_max * (cursor_width + @column_spacing)
      y = item / @column_max * @row_height - @virtualOy
      return Rect.new(x, y, cursor_width, @row_height)
    end
  end

  def drawCursor(index,rect)
    if self.index==index
      bmp = (@sorting) ? @swaparrow.bitmap : @selarrow.bitmap
      pbCopyBitmap(self.contents,bmp,rect.x,rect.y+14)
    end
  end

  def drawItem(index,_count,rect)
    textpos = []
    rect = Rect.new(rect.x+16,rect.y-42,rect.width-16,rect.height) 
    ypos = rect.y+6+56
	ypos_qty = rect.y+20+58
    thispocket = @bag.pockets[@pocket]
    if index==self.itemCount-1
      textpos.push([_INTL("CANCEL"),rect.x,ypos,false,self.baseColor,self.shadowColor]) #CLOSE BAG
    else
      item = (@filterlist) ? thispocket[@filterlist[@pocket][index]][0] : thispocket[index][0]
      baseColor   = self.baseColor
      shadowColor = self.shadowColor
      if @sorting && index==self.index
	    if $Trainer.male?
          baseColor   = Color.new(0,0,255)
		else
		  baseColor   = Color.new(255,0,0)
		end
        shadowColor = Color.new(255,255,255,0)
      end
      textpos.push(
         [@adapter.getDisplayName(item),rect.x,ypos,false,baseColor,shadowColor]
      )
      if !pbIsImportantItem?(item)   # Not a Key item or HM (or infinite TM)
        qty = (@filterlist) ? thispocket[@filterlist[@pocket][index]][1] : thispocket[index][1]
        qtytext = _ISPRINTF("x {1: 3d}",qty)
        xQty    = rect.x+rect.width-self.contents.text_size(qtytext).width-16
        textpos.push([qtytext,xQty,ypos_qty,false,baseColor,shadowColor])
      end
    end
    pbDrawTextPositions(self.contents,textpos)
  end

  def refresh
    @item_max = itemCount()
    self.update_cursor_rect
    dwidth  = self.width-self.borderX
    dheight = self.height-self.borderY
    self.contents = pbDoEnsureBitmap(self.contents,dwidth,dheight)
    self.contents.clear
    for i in 0...@item_max
      next if i<self.top_item || i>=self.top_item+self.page_item_max
      drawItem(i,@item_max,itemRect(i))
    end
    drawCursor(self.index,itemRect(self.index))
  end

  def update
    super
    @uparrow.visible   = false
    @downarrow.visible = false
  end
end



#===============================================================================
# Bag visuals
#===============================================================================
class PokemonBag_Scene
  ITEMLISTBASECOLOR     = Color.new(0,0,0)
  ITEMLISTSHADOWCOLOR   = Color.new(255,255,255,0)
  ITEMTEXTBASECOLOR     = Color.new(0,0,0)
  ITEMTEXTSHADOWCOLOR   = Color.new(255,255,255,0)
  POCKETNAMEBASECOLOR   = Color.new(255,255,255)
  POCKETNAMESHADOWCOLOR = Color.new(255,255,255,0)
  ITEMSVISIBLE          = 5

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(bag,choosing=false,filterproc=nil,resetpocket=true)
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @bag        = bag
    @choosing   = choosing
    @filterproc = filterproc
    pbRefreshFilter
    lastpocket = @bag.lastpocket
    numfilledpockets = @bag.pockets.length-1
    if @choosing
      numfilledpockets = 0
      if @filterlist!=nil
        for i in 1...@bag.pockets.length
          numfilledpockets += 1 if @filterlist[i].length>0
        end
      else
        for i in 1...@bag.pockets.length
          numfilledpockets += 1 if @bag.pockets[i].length>0
        end
      end
      lastpocket = (resetpocket) ? 1 : @bag.lastpocket
      if (@filterlist && @filterlist[lastpocket].length==0) ||
         (!@filterlist && @bag.pockets[lastpocket].length==0)
        for i in 1...@bag.pockets.length
          if @filterlist && @filterlist[i].length>0
            lastpocket = i; break
          elsif !@filterlist && @bag.pockets[i].length>0
            lastpocket = i; break
          end
        end
      end
    end
    @bag.lastpocket = lastpocket
    @sprites = {}
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["bagsprite"] = IconSprite.new(0,48,@viewport)
    @sprites["pocketicon"] = BitmapSprite.new(186,32,@viewport)
    @sprites["itemlist"] = Window_PokemonBag.new(@bag,@filterlist,lastpocket,64,-12,280,64+ITEMSVISIBLE*48) #64, y value = 14 (-24) Default: y =-8, multiplier*32
    @sprites["itemlist"].viewport    = @viewport
    @sprites["itemlist"].pocket      = lastpocket
    @sprites["itemlist"].index       = @bag.getChoice(lastpocket)
    @sprites["itemlist"].baseColor   = ITEMLISTBASECOLOR
    @sprites["itemlist"].shadowColor = ITEMLISTSHADOWCOLOR
    @sprites["itemicon"] = ItemIconSprite.new(1000,Graphics.height-800,-1,@viewport)
    @sprites["itemtext"] = Window_UnformattedTextPokemon.new("")
    @sprites["itemtext"].x           = 0
    @sprites["itemtext"].y           = 192
    @sprites["itemtext"].width       = Graphics.width-0
    @sprites["itemtext"].height      = 96
    @sprites["itemtext"].baseColor   = ITEMTEXTBASECOLOR
    @sprites["itemtext"].shadowColor = ITEMTEXTSHADOWCOLOR
    @sprites["itemtext"].visible     = true
    @sprites["itemtext"].viewport    = @viewport
    @sprites["itemtext"].windowskin  = nil
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.new("")
    @sprites["helpwindow"].visible  = false
    @sprites["helpwindow"].viewport = @viewport
    @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
    @sprites["msgwindow"].visible  = false
    @sprites["msgwindow"].viewport = @viewport
    pbBottomLeftLines(@sprites["helpwindow"],1)
    pbDeactivateWindows(@sprites)
    pbRefresh
    pbFadeInAndShow(@sprites)
  end

  def pbFadeOutScene
    @oldsprites = pbFadeOutAndHide(@sprites)
  end

  def pbFadeInScene
    pbFadeInAndShow(@sprites,@oldsprites)
    @oldsprites = nil
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) if !@oldsprites
    @oldsprites = nil
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbDisplay(msg,brief=false)
    UIHelper.pbDisplay(@sprites["msgwindow"],msg,brief) { pbUpdate }
  end

  def pbConfirm(msg)
    UIHelper.pbConfirm(@sprites["msgwindow"],msg) { pbUpdate }
  end

  def pbChooseNumber(helptext,maximum,initnum=1)
    return UIHelper.pbChooseNumber(@sprites["helpwindow"],helptext,maximum,initnum) { pbUpdate }
  end

  def pbShowCommands(helptext,commands,index=0)
    return UIHelper.pbShowCommands(@sprites["helpwindow"],helptext,commands,index) { pbUpdate }
  end

  def pbRefresh
    # Set the background image
	if $Trainer.female?
    @sprites["background"].setBitmap(sprintf("Graphics/Pictures/Bag/bgf_#{@bag.lastpocket}"))
	else
	@sprites["background"].setBitmap(sprintf("Graphics/Pictures/Bag/bg_#{@bag.lastpocket}"))
	end
    # Set the bag sprite
    fbagexists = pbResolveBitmap(sprintf("Graphics/Pictures/Bag/bag_#{@bag.lastpocket}_f"))
    if $Trainer.female? && fbagexists
      @sprites["bagsprite"].setBitmap("Graphics/Pictures/Bag/bag_#{@bag.lastpocket}_f")
    else
      @sprites["bagsprite"].setBitmap("Graphics/Pictures/Bag/bag_#{@bag.lastpocket}")
    end
    # Refresh the item window
    @sprites["itemlist"].refresh
    # Refresh more things
    pbRefreshIndexChanged
  end

  def pbRefreshIndexChanged
    itemlist = @sprites["itemlist"]
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Set the selected item's description
    @sprites["itemtext"].text = (itemlist.item==0) ? _INTL("") : #Close bag
       pbGetMessage(MessageTypes::ItemDescriptions,itemlist.item)
  end

  def pbRefreshFilter
    @filterlist = nil
    return if !@choosing
    return if @filterproc==nil
    @filterlist = []
    for i in 1...@bag.pockets.length
      @filterlist[i] = []
      for j in 0...@bag.pockets[i].length
        @filterlist[i].push(j) if @filterproc.call(@bag.pockets[i][j][0])
      end
    end
  end

  # Called when the item screen wants an item to be chosen from the screen
  def pbChooseItem
    @sprites["helpwindow"].visible = false
    itemwindow = @sprites["itemlist"]
    thispocket = @bag.pockets[itemwindow.pocket]
    swapinitialpos = -1
    pbActivateWindow(@sprites,"itemlist") {
      loop do
        oldindex = itemwindow.index
        Graphics.update
        Input.update
        pbUpdate
        if itemwindow.sorting && itemwindow.index>=thispocket.length
          itemwindow.index = (oldindex==thispocket.length-1) ? 0 : thispocket.length-1
        end
        if itemwindow.index!=oldindex
          # Move the item being switched
          if itemwindow.sorting
            thispocket.insert(itemwindow.index,thispocket.delete_at(oldindex))
          end
          # Update selected item for current pocket
          @bag.setChoice(itemwindow.pocket,itemwindow.index)
          pbRefresh
        end
        if itemwindow.sorting
          if Input.trigger?(Input::A) ||
             Input.trigger?(Input::C)
            itemwindow.sorting = false
            pbPlayDecisionSE
            pbRefresh
          elsif Input.trigger?(Input::B)
            thispocket.insert(swapinitialpos,thispocket.delete_at(itemwindow.index))
            itemwindow.index = swapinitialpos
            itemwindow.sorting = false
            pbPlayCancelSE
            pbRefresh
          end
        else
          # Change pockets
          if Input.trigger?(Input::LEFT)
            newpocket = itemwindow.pocket
            loop do
              newpocket = (newpocket==1) ? PokemonBag.numPockets : newpocket-1
              break if !@choosing || newpocket==itemwindow.pocket
              if @filterlist; break if @filterlist[newpocket].length>0
              else; break if @bag.pockets[newpocket].length>0
              end
            end
            if itemwindow.pocket!=newpocket
              itemwindow.pocket = newpocket
              @bag.lastpocket   = itemwindow.pocket
              thispocket = @bag.pockets[itemwindow.pocket]
              pbSEPlay("Pack_ChangePocket",90)
              pbRefresh
            end
          elsif Input.trigger?(Input::RIGHT)
            newpocket = itemwindow.pocket
            loop do
              newpocket = (newpocket==PokemonBag.numPockets) ? 1 : newpocket+1
              break if !@choosing || newpocket==itemwindow.pocket
              if @filterlist; break if @filterlist[newpocket].length>0
              else; break if @bag.pockets[newpocket].length>0
              end
            end
            if itemwindow.pocket!=newpocket
              itemwindow.pocket = newpocket
              @bag.lastpocket   = itemwindow.pocket
              thispocket = @bag.pockets[itemwindow.pocket]
              pbSEPlay("Pack_ChangePocket",80,100)
              pbRefresh
            end
#          elsif Input.trigger?(Input::F5)   # Register/unregister selected item
#            if !@choosing && itemwindow.index<thispocket.length
#              if @bag.pbIsRegistered?(itemwindow.item)
#                @bag.pbUnregisterItem(itemwindow.item)
#              elsif pbCanRegisterItem?(itemwindow.item)
#                @bag.pbRegisterItem(itemwindow.item)
#              end
#              pbPlayDecisionSE
#              pbRefresh
#            end
          elsif Input.trigger?(Input::A)   # Start switching the selected item
            if !@choosing
              if thispocket.length>1 && itemwindow.index<thispocket.length &&
                 !BAG_POCKET_AUTO_SORT[itemwindow.pocket]
                itemwindow.sorting = true
                swapinitialpos = itemwindow.index
                pbPlayDecisionSE
                pbRefresh
              end
            end
          elsif Input.trigger?(Input::B)   # Cancel the item screen
            pbPlayCloseMenuSE
            return 0
          elsif Input.trigger?(Input::C)   # Choose selected item
            (itemwindow.item==0) ? pbPlayCloseMenuSE : pbPlayDecisionSE
            return itemwindow.item
          end
        end
      end
    }
  end
end



#===============================================================================
# Bag mechanics
#===============================================================================
class PokemonBagScreen
  def initialize(scene,bag)
    @bag   = bag
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene(@bag)
    item = 0
    loop do
      item = @scene.pbChooseItem
      break if item==0
      cmdRead     = -1
      cmdUse      = -1
      cmdRegister = -1
      cmdGive     = -1
      cmdToss     = -1
      cmdDebug    = -1
      commands = []
      # Generate command list
      commands[cmdRead = commands.length]       = _INTL("READ") if pbIsMail?(item)
      if ItemHandlers.hasOutHandler(item) || (pbIsMachine?(item) && $Trainer.party.length>0)
        if ItemHandlers.hasUseText(item)
          commands[cmdUse = commands.length]    = ItemHandlers.getUseText(item)
        else
          commands[cmdUse = commands.length]    = _INTL("USE")
        end
      end
      commands[cmdGive = commands.length]       = _INTL("GIVE") if $Trainer.pokemonParty.length>0 && pbCanHoldItem?(item)
      commands[cmdToss = commands.length]       = _INTL("TOSS") if !pbIsImportantItem?(item) || $DEBUG
      if @bag.pbIsRegistered?(item)
        commands[cmdRegister = commands.length] = _INTL("DESELECT")
      elsif pbCanRegisterItem?(item)
        commands[cmdRegister = commands.length] = _INTL("REG.")
      end
      commands[cmdDebug = commands.length]      = _INTL("DEBUG") if $DEBUG
      commands[commands.length]                 = _INTL("CANCEL")
      # Show commands generated above
      itemname = PBItems.getName(item)
      command = @scene.pbShowCommands(nil,commands)
      if cmdRead>=0 && command==cmdRead   # Read mail
        pbFadeOutIn {
          pbDisplayMail(PokemonMail.new(item,"",""))
        }
      elsif cmdUse>=0 && command==cmdUse   # Use item
        ret = pbUseItem(@bag,item,@scene)
        # ret: 0=Item wasn't used; 1=Item used; 2=Close Bag to use in field
        break if ret==2   # End screen
        @scene.pbRefresh
        next
      elsif cmdGive>=0 && command==cmdGive   # Give item to Pokémon
        if $Trainer.pokemonCount==0
          @scene.pbDisplay(_INTL("There is no POKéMON."))
        elsif pbIsImportantItem?(item)
          @scene.pbDisplay(_INTL("The {1} can't be held.",itemname))
        else
          pbFadeOutIn {
            sscene = PokemonParty_Scene.new
            sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
            sscreen.pbPokemonGiveScreen(item)
            @scene.pbRefresh
          }
        end
      elsif cmdToss>=0 && command==cmdToss   # Toss item
        qty = @bag.pbQuantity(item)
        if qty>1
          helptext = _INTL("Toss out how many {1}?",PBItems.getNamePlural(item))
          qty = @scene.pbChooseNumber(helptext,qty)
        end
        if qty>0
          itemname = PBItems.getNamePlural(item) if qty>1
          if pbConfirm(_INTL("Is it OK to throw away {1} {2}?",qty,itemname))
            pbDisplay(_INTL("Threw away {1} {2}.",qty,itemname))
            qty.times { @bag.pbDeleteItem(item) }
            @scene.pbRefresh
          end
        end
      elsif cmdRegister>=0 && command==cmdRegister   # Register item
        if @bag.pbIsRegistered?(item)
          @bag.pbUnregisterItem(item)
        else
          @bag.pbRegisterItem(item)
        end
        @scene.pbRefresh
      elsif cmdDebug>=0 && command==cmdDebug   # Debug
        command = 0
        loop do
          command = @scene.pbShowCommands(_INTL("Do what with {1}?",itemname),[
            _INTL("Change quantity"),
            _INTL("Make Mystery Gift"),
            _INTL("Cancel")
            ],command)
          case command
          ### Cancel ###
          when -1, 2
            break
          ### Change quantity ###
          when 0
            qty = @bag.pbQuantity(item)
            itemplural = PBItems.getNamePlural(item)
            params = ChooseNumberParams.new
            params.setRange(0,BAG_MAX_PER_SLOT)
            params.setDefaultValue(qty)
            newqty = pbMessageChooseNumber(
               _INTL("Choose new quantity of {1} (max. #{BAG_MAX_PER_SLOT}).",itemplural),params) { @scene.pbUpdate }
            if newqty>qty
              @bag.pbStoreItem(item,newqty-qty)
            elsif newqty<qty
              @bag.pbDeleteItem(item,qty-newqty)
            end
            @scene.pbRefresh
            break if newqty==0
          ### Make Mystery Gift ###
          when 1
            pbCreateMysteryGift(1,item)
          end
        end
      end
    end
    @scene.pbEndScene
    return item
  end

  def pbDisplay(text)
    @scene.pbDisplay(text)
  end

  def pbConfirm(text)
    return @scene.pbConfirm(text)
  end

  # UI logic for the item screen for choosing an item.
  def pbChooseItemScreen(proc=nil)
    oldlastpocket = @bag.lastpocket
    oldchoices = @bag.getAllChoices
    @scene.pbStartScene(@bag,true,proc)
    item = @scene.pbChooseItem
    @scene.pbEndScene
    @bag.lastpocket = oldlastpocket
    @bag.setAllChoices(oldchoices)
    return item
  end

  # UI logic for withdrawing an item in the item storage screen.
  def pbWithdrawItemScreen
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    @scene.pbStartScene(storage)
    loop do
      item = @scene.pbChooseItem
      break if item==0
      qty = storage.pbQuantity(item)
      if qty>1 && !pbIsImportantItem?(item)
        qty = @scene.pbChooseNumber(_INTL("How many do you want to withdraw?"),qty)
      end
      next if qty<=0
      if @bag.pbCanStore?(item,qty)
        if !storage.pbDeleteItem(item,qty)
          raise "Can't delete items from storage"
        end
        if !@bag.pbStoreItem(item,qty)
          raise "Can't withdraw items from storage"
        end
        @scene.pbRefresh
        dispqty = (pbIsImportantItem?(item)) ? 1 : qty
        itemname = (dispqty>1) ? PBItems.getNamePlural(item) : PBItems.getName(item)
        pbDisplay(_INTL("Withdrew {1} {2}.",dispqty,itemname))
      else
        pbDisplay(_INTL("There's no more room in the Bag."))
      end
    end
    @scene.pbEndScene
  end

  # UI logic for depositing an item in the item storage screen.
  def pbDepositItemScreen
    @scene.pbStartScene(@bag)
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    item = 0
    loop do
      item = @scene.pbChooseItem
      break if item==0
      qty = @bag.pbQuantity(item)
      if qty>1 && !pbIsImportantItem?(item)
        qty = @scene.pbChooseNumber(_INTL("How many do you want to deposit?"),qty)
      end
      if qty>0
        if !storage.pbCanStore?(item,qty)
          pbDisplay(_INTL("There's no room to store items."))
        else
          if !@bag.pbDeleteItem(item,qty)
            raise "Can't delete items from Bag"
          end
          if !storage.pbStoreItem(item,qty)
            raise "Can't deposit items to storage"
          end
          @scene.pbRefresh
          dispqty  = (pbIsImportantItem?(item)) ? 1 : qty
          itemname = (dispqty>1) ? PBItems.getNamePlural(item) : PBItems.getName(item)
          pbDisplay(_INTL("Deposited {1} {2}.",dispqty,itemname))
        end
      end
    end
    @scene.pbEndScene
  end

  # UI logic for tossing an item in the item storage screen.
  def pbTossItemScreen
    if !$PokemonGlobal.pcItemStorage
      $PokemonGlobal.pcItemStorage = PCItemStorage.new
    end
    storage = $PokemonGlobal.pcItemStorage
    @scene.pbStartScene(storage)
    loop do
      item = @scene.pbChooseItem
      break if item==0
      if pbIsImportantItem?(item)
        @scene.pbDisplay(_INTL("That's too important to toss out!"))
        next
      end
      qty = storage.pbQuantity(item)
      itemname       = PBItems.getName(item)
      itemnameplural = PBItems.getNamePlural(item)
      if qty>1
        qty=@scene.pbChooseNumber(_INTL("Toss out how many {1}?",itemnameplural),qty)
      end
      if qty>0
        itemname = itemnameplural if qty>1
        if pbConfirm(_INTL("Is it OK to throw away {1} {2}?",qty,itemname))
          if !storage.pbDeleteItem(item,qty)
            raise "Can't delete items from storage"
          end
          @scene.pbRefresh
          pbDisplay(_INTL("Threw away {1} {2}.",qty,itemname))
        end
      end
    end
    @scene.pbEndScene
  end
end
