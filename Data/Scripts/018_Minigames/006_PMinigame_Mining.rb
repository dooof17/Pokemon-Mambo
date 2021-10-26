################################################################################
# "Mining" mini-game
# By Maruno
#-------------------------------------------------------------------------------
# Run with:      pbMiningGame
################################################################################
class MiningGameCounter < BitmapSprite
  attr_accessor :hits

  def initialize(x,y)
    @viewport=Viewport.new(x,y,320,32)
    @viewport.z=99999
    super(320,32,@viewport)
    @hits=0
    @image=AnimatedBitmap.new(_INTL("Graphics/Pictures/Mining/cracks"))
    update
  end

  def update
    self.bitmap.clear
    value=@hits
    startx=320-48
    while value>6
      self.bitmap.blt(startx,0,@image.bitmap,Rect.new(0,0,48,32))
      startx-=48
      value-=6
    end
    startx-=48
    if value>0
      self.bitmap.blt(startx,0,@image.bitmap,Rect.new(0,value*32,96,32))
    end
  end
end



class MiningGameTile < BitmapSprite
  attr_reader :layer

  def initialize(x,y)
    @viewport=Viewport.new(x,y,16,16)
    @viewport.z=99999
    super(16,16,@viewport)
    r = rand(100)
    if r<10;    @layer = 2   # 10%
    elsif r<25; @layer = 3   # 15%
    elsif r<60; @layer = 4   # 35%
    elsif r<85; @layer = 5   # 25%
    else;       @layer = 6   # 15%
    end
    @image=AnimatedBitmap.new(_INTL("Graphics/Pictures/Mining/tiles"))
    update
  end

  def layer=(value)
    @layer=value
    @layer=0 if @layer<0
  end

  def update
    self.bitmap.clear
    if @layer>0
      self.bitmap.blt(0,0,@image.bitmap,Rect.new(0,16*(@layer-1),16,16))
    end
  end
end



class MiningGameCursor < BitmapSprite
  attr_accessor :mode
  attr_accessor :position
  attr_accessor :hit
  attr_accessor :counter
  ToolPositions = [[1,0],[1,1],[1,1],[0,0],[0,0],
                   [0,2],[0,2],[0,0],[0,0],[0,2],[0,2]]   # Graphic, position

  def initialize(position=0,mode=0)   # mode: 0=pick, 1=hammer
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    super(Graphics.width,Graphics.height,@viewport)
    @position = position
    @mode     = mode
    @hit      = 0   # 0=regular, 1=hit item, 2=hit iron
    @counter  = 0
    @cursorbitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Mining/cursor"))
    @toolbitmap   = AnimatedBitmap.new(_INTL("Graphics/Pictures/Mining/tools"))
    @hitsbitmap   = AnimatedBitmap.new(_INTL("Graphics/Pictures/Mining/hits"))
    update
  end

  def isAnimating?
    return @counter>0
  end

  def animate(hit)
    @counter = 22
    @hit     = hit
  end

  def update
    self.bitmap.clear
    x = 16*(@position%MiningGameScene::BOARDWIDTH)
    y = 16*(@position/MiningGameScene::BOARDWIDTH)
    if @counter>0
      @counter -= 1
      toolx = x; tooly = y
      i = 10-(@counter/2).floor
      if ToolPositions[i][1]==1
        toolx -= 8; tooly += 8
      elsif ToolPositions[i][1]==2
        toolx += 6
      end
      self.bitmap.blt(toolx,tooly,@toolbitmap.bitmap,
                      Rect.new(48*ToolPositions[i][0],48*@mode,48,48))
      if i<5 && i%2==0
        if @hit==2
          self.bitmap.blt(x-32,y,@hitsbitmap.bitmap,Rect.new(80*2,0,80,80))
        else
          self.bitmap.blt(x-32,y,@hitsbitmap.bitmap,Rect.new(80*@mode,0,80,80))
        end
      end
      if @hit==1 && i<3
        self.bitmap.blt(x-32,y,@hitsbitmap.bitmap,Rect.new(80*i,80,80,80))
      end
    else
      self.bitmap.blt(x,y+32,@cursorbitmap.bitmap,Rect.new(16*@mode,0,16,16))
    end
  end
end



class MiningGameScene
  BOARDWIDTH  = 16
  BOARDHEIGHT = 16
  ITEMS = [   # Item, probability, graphic x, graphic y, width, height, pattern
	   [:DOMEFOSSIL,20, 0,4, 2,2,[1,1,1,1]],      # 0
     [:HELIXFOSSIL,20, 2,4, 2,2,[1,1,1,1]],     # 1
     [:OLDAMBER,20, 4,4, 2,2,[1,1,1,1]],        # 2
     [:ROOTFOSSIL,20, 6,4, 2,2,[1,1,1,1]],      # 3
     [:CLAWFOSSIL,20, 8,4, 2,2,[1,1,1,1]],      # 4
     [:SKULLFOSSIL,20, 10,4, 2,2,[1,1,1,1]],    # 5
     [:ARMORFOSSIL,20, 12,4, 2,2,[1,1,1,1]],    # 6
     [:COVERFOSSIL,20, 14,4, 2,2,[1,1,1,1]],    # 7
     [:PLUMEFOSSIL,20, 16,4, 2,2,[1,1,1,1]],    # 8
     [:JAWFOSSIL,20, 18,4, 2,2,[1,1,1,1]],      # 9
     [:SAILFOSSIL,20, 0,6, 2,2,[1,1,1,1]],      # 10
     [:FOSSILIZEDBIRD,20, 2,6, 2,2,[1,1,1,1]],  # 11
     [:FOSSILIZEDFISH,20, 4,6, 2,2,[1,1,1,1]],  # 12
     [:FOSSILIZEDDRAKE,20, 6,6, 2,2,[1,1,1,1]], # 13
     [:FOSSILIZEDDINO,20, 8,6, 2,2,[1,1,1,1]],  # 14
     [:FIRESTONE,20, 10,6, 2,2,[1,1,1,1]],      # 15
     [:WATERSTONE,20, 12,6, 2,2,[1,1,1,1]],     # 16
     [:THUNDERSTONE,20, 14,6, 2,2,[1,1,1,1]],   # 17
     [:LEAFSTONE,20, 16,6, 2,2,[1,1,1,1]],      # 18
     [:MOONSTONE,20, 18,6, 2,2,[1,1,1,1]],      # 19
     [:SUNSTONE,20, 0,8, 2,2,[1,1,1,1]],        # 20
     [:OVALSTONE,150, 2,8, 2,2,[1,1,1,1]],      # 21
     [:EVERSTONE,150, 4,8, 2,2,[1,1,1,1]],      # 22
     [:STARPIECE,100, 6,8, 2,2,[1,1,1,1]],      # 23
     [:REVIVE,100, 8,8, 2,2,[1,1,1,1]],         # 24
     [:MAXREVIVE,50, 10,8, 2,2,[1,1,1,1]],      # 25
     [:RAREBONE,100, 12,8, 2,2,[1,1,1,1]],      # 26
     [:LIGHTCLAY,100, 14,8, 2,2,[1,1,1,1]],     # 27
     [:HARDSTONE,200, 16,8, 2,2,[1,1,1,1]],     # 28
     [:HEARTSCALE,200, 18,8, 2,2,[1,1,1,1]],    # 29
     [:IRONBALL,100, 0,10, 2,2,[1,1,1,1]],      # 30
     [:ODDKEYSTONE,100, 2,10, 2,2,[1,1,1,1]],   # 31
     [:HEATROCK,50, 4,10, 2,2,[1,1,1,1]],       # 32
     [:DAMPROCK,50, 6,10, 2,2,[1,1,1,1]],       # 33
     [:SMOOTHROCK,50, 8,10, 2,2,[1,1,1,1]],     # 34
     [:ICYROCK,50, 10,10, 2,2,[1,1,1,1]],       # 35
     [:REDSHARD,100, 12,10, 2,2,[1,1,1,1]],     # 36
     [:GREENSHARD,100, 14,10, 2,2,[1,1,1,1]],   # 37
     [:YELLOWSHARD,100, 16,10, 2,2,[1,1,1,1]],  # 38
     [:BLUESHARD,100, 18,10, 2,2,[1,1,1,1]],    # 39
     [:INSECTPLATE,10, 0,12, 2,2,[1,1,1,1]],    # 40
     [:DREADPLATE,10, 2,12, 2,2,[1,1,1,1]],     # 41
     [:DRACOPLATE,10, 4,12, 2,2,[1,1,1,1]],     # 42
     [:ZAPPLATE,10, 6,12, 2,2,[1,1,1,1]],       # 43
     [:FISTPLATE,10, 8,12, 2,2,[1,1,1,1]],      # 44
     [:FLAMEPLATE,10, 10,12, 2,2,[1,1,1,1]],    # 45
     [:MEADOWPLATE,10, 12,12, 2,2,[1,1,1,1]],   # 46
     [:EARTHPLATE,10, 14,12, 2,2,[1,1,1,1]],    # 47
     [:ICICLEPLATE,10, 16,12, 2,2,[1,1,1,1]],   # 48
     [:TOXICPLATE,10, 18,12, 2,2,[1,1,1,1]],    # 49
     [:MINDPLATE,10, 0,14, 2,2,[1,1,1,1]],      # 50
     [:STONEPLATE,10, 2,14, 2,2,[1,1,1,1]],     # 51
     [:SKYPLATE,10, 4,14, 2,2,[1,1,1,1]],       # 52
     [:SPOOKYPLATE,10, 6,14, 2,2,[1,1,1,1]],    # 53
     [:IRONPLATE,10, 8,14, 2,2,[1,1,1,1]],      # 54
     [:SPLASHPLATE,10, 10,14, 2,2,[1,1,1,1]],   # 55
     [:PIXIEPLATE,10, 12,14, 2,2,[1,1,1,1]]     # 56
  ]
  IRON = [   # Graphic x, graphic y, width, height, pattern
     [0,0, 1,4,[1,1,1,1]],
     [1,0, 2,4,[1,1,1,1,1,1,1,1]],
     [3,0, 4,2,[1,1,1,1,1,1,1,1]],
     [3,2, 4,1,[1,1,1,1]],
     [7,0, 3,3,[1,1,1,1,1,1,1,1,1]],
     [0,5, 3,2,[1,1,0,0,1,1]],
     [0,7, 3,2,[0,1,0,1,1,1]],
     [3,5, 3,2,[0,1,1,1,1,0]],
     [3,7, 3,2,[1,1,1,0,1,0]],
     [6,3, 2,3,[1,0,1,1,0,1]],
     [8,3, 2,3,[0,1,1,1,1,0]],
     [6,6, 2,3,[1,0,1,1,1,0]],
     [8,6, 2,3,[0,1,1,1,0,1]]
  ]

  def update
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    addBackgroundPlane(@sprites,"bg","Mining/miningbg",@viewport)
    @sprites["itemlayer"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @itembitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/Mining/items"))
    @ironbitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/Mining/irons"))
    @items=[]
    @itemswon=[]
    @iron=[]
    pbDistributeItems
    pbDistributeIron
    for i in 0...BOARDHEIGHT
      for j in 0...BOARDWIDTH
        @sprites["tile#{j+i*BOARDWIDTH}"]=MiningGameTile.new(16*j,32+16*i)
      end
    end
    @sprites["crack"]=MiningGameCounter.new(0,0)
    @sprites["cursor"]=MiningGameCursor.new(0,0)   # start position (top left), pick
    @sprites["tool"]=IconSprite.new(268,176,@viewport)
    @sprites["tool"].setBitmap(sprintf("Graphics/Pictures/Mining/toolicons"))
    @sprites["tool"].src_rect.set(0,0,40,40)
    update
    pbFadeInAndShow(@sprites)
  end

  def pbDistributeItems
    # Set items to be buried (index in ITEMS, x coord, y coord)
    ptotal=0
    for i in ITEMS
      ptotal+=i[1]
    end
    numitems=2+rand(3)
    tries = 0
    while numitems>0
      rnd=rand(ptotal)
      added=false
      for i in 0...ITEMS.length
        rnd-=ITEMS[i][1]
        if rnd<0
          if pbNoDuplicateItems(ITEMS[i][0])
            while !added
              provx=rand(BOARDWIDTH-ITEMS[i][4]+1)
              provy=rand(BOARDHEIGHT-ITEMS[i][5]+1)
              if pbCheckOverlaps(false,provx,provy,ITEMS[i][4],ITEMS[i][5],ITEMS[i][6])
                @items.push([i,provx,provy])
                numitems-=1
                added=true
              end
            end
          else
            break
          end
        end
        break if added
      end
      tries += 1
      break if tries>=500
    end
    # Draw items on item layer
    layer=@sprites["itemlayer"].bitmap
    for i in @items
      ox=ITEMS[i[0]][2]
      oy=ITEMS[i[0]][3]
      rectx=ITEMS[i[0]][4]
      recty=ITEMS[i[0]][5]
      p @items
      layer.blt(16*i[1],32+16*i[2],@itembitmap.bitmap,Rect.new(16*ox,16*oy,16*rectx,16*recty))
    end
  end

  def pbDistributeIron
    # Set iron to be buried (index in IRON, x coord, y coord)
    numitems=4+rand(3)
    tries = 0
    while numitems>0
      rnd=rand(IRON.length)
      provx=rand(BOARDWIDTH-IRON[rnd][2]+1)
      provy=rand(BOARDHEIGHT-IRON[rnd][3]+1)
      if pbCheckOverlaps(true,provx,provy,IRON[rnd][2],IRON[rnd][3],IRON[rnd][4])
        @iron.push([rnd,provx,provy])
        numitems-=1
      end
      tries += 1
      break if tries>=500
    end
    # Draw items on item layer
    layer=@sprites["itemlayer"].bitmap
    for i in @iron
      ox=IRON[i[0]][0]
      oy=IRON[i[0]][1]
      rectx=IRON[i[0]][2]
      recty=IRON[i[0]][3]
      layer.blt(16*i[1],32+16*i[2],@ironbitmap.bitmap,Rect.new(16*ox,16*oy,16*rectx,16*recty))
    end
  end

  def pbNoDuplicateItems(newitem)
    return true if newitem==:HEARTSCALE   # Allow multiple Heart Scales
    fossils=[:DOMEFOSSIL,:HELIXFOSSIL,:OLDAMBER,:ROOTFOSSIL,
            :CLAWFOSSIL,:SKULLFOSSIL,:ARMORFOSSIL,:COVERFOSSIL,
            :PLUMEFOSSIL,:JAWFOSSIL,:SAILFOSSIL,:FOSSILIZEDBIRD,
            :FOSSILIZEDFISH,:FOSSILIZEDDRAKE,:FOSSILIZEDDINO]
    plates=[:INSECTPLATE,:DREADPLATE,:DRACOPLATE,:ZAPPLATE,:FISTPLATE,
            :FLAMEPLATE,:MEADOWPLATE,:EARTHPLATE,:ICICLEPLATE,:TOXICPLATE,
            :MINDPLATE,:STONEPLATE,:SKYPLATE,:SPOOKYPLATE,:IRONPLATE,:SPLASHPLATE,:PIXIEPLATE]
    for i in @items
      preitem=ITEMS[i[0]][0]
      return false if preitem==newitem   # No duplicate items
      return false if fossils.include?(preitem) && fossils.include?(newitem)
      return false if plates.include?(preitem) && plates.include?(newitem)
    end
    return true
  end

  def pbCheckOverlaps(checkiron,provx,provy,provwidth,provheight,provpattern)
    for i in @items
      prex=i[1]
      prey=i[2]
      prewidth=ITEMS[i[0]][4]
      preheight=ITEMS[i[0]][5]
      prepattern=ITEMS[i[0]][6]
      next if provx+provwidth<=prex || provx>=prex+prewidth ||
              provy+provheight<=prey || provy>=prey+preheight
      for j in 0...prepattern.length
        next if prepattern[j]==0
        xco=prex+(j%prewidth)
        yco=prey+(j/prewidth).floor
        next if provx+provwidth<=xco || provx>xco ||
                provy+provheight<=yco || provy>yco
        return false if provpattern[xco-provx+(yco-provy)*provwidth]==1
      end
    end
    if checkiron   # Check other irons as well
      for i in @iron
        prex=i[1]
        prey=i[2]
        prewidth=IRON[i[0]][2]
        preheight=IRON[i[0]][3]
        prepattern=IRON[i[0]][4]
        next if provx+provwidth<=prex || provx>=prex+prewidth ||
                provy+provheight<=prey || provy>=prey+preheight
        for j in 0...prepattern.length
          next if prepattern[j]==0
          xco=prex+(j%prewidth)
          yco=prey+(j/prewidth).floor
          next if provx+provwidth<=xco || provx>xco ||
                  provy+provheight<=yco || provy>yco
          return false if provpattern[xco-provx+(yco-provy)*provwidth]==1
        end
      end
    end
    return true
  end

  def pbHit
    hittype=0
    position=@sprites["cursor"].position
    if @sprites["cursor"].mode==1   # Hammer
      pattern=[1,2,1,
               2,2,2,
               1,2,1]
      @sprites["crack"].hits+=2 if !($DEBUG && Input.press?(Input::CTRL))
    else                            # Pick
      pattern=[0,1,0,
               1,2,1,
               0,1,0]
      @sprites["crack"].hits+=1 if !($DEBUG && Input.press?(Input::CTRL))
    end
    if @sprites["tile#{position}"].layer<=pattern[4] && pbIsIronThere?(position)
      @sprites["tile#{position}"].layer-=pattern[4]
      pbSEPlay("Mining iron")
      hittype=2
    else
      for i in 0..2
        ytile=i-1+position/BOARDWIDTH
        next if ytile<0 || ytile>=BOARDHEIGHT
        for j in 0..2
          xtile=j-1+position%BOARDWIDTH
          next if xtile<0 || xtile>=BOARDWIDTH
          @sprites["tile#{xtile+ytile*BOARDWIDTH}"].layer-=pattern[j+i*3]
        end
      end
      if @sprites["cursor"].mode==1   # Hammer
        pbSEPlay("Mining hammer")
      else
        pbSEPlay("Mining pick")
      end
    end
    update
    Graphics.update
    hititem=(@sprites["tile#{position}"].layer==0 && pbIsItemThere?(position))
    hittype=1 if hititem
    @sprites["cursor"].animate(hittype)
    revealed=pbCheckRevealed
    if revealed.length>0
      pbSEPlay("Mining reveal full")
      pbFlashItems(revealed)
    elsif hititem
      pbSEPlay("Mining reveal")
    end
  end

  def pbIsItemThere?(position)
    posx=position%BOARDWIDTH
    posy=position/BOARDWIDTH
    for i in @items
      index=i[0]
      width=ITEMS[index][4]
      height=ITEMS[index][5]
      pattern=ITEMS[index][6]
      next if posx<i[1] || posx>=(i[1]+width)
      next if posy<i[2] || posy>=(i[2]+height)
      dx=posx-i[1]
      dy=posy-i[2]
      return true if pattern[dx+dy*width]>0
    end
    return false
  end

  def pbIsIronThere?(position)
    posx=position%BOARDWIDTH
    posy=position/BOARDWIDTH
    for i in @iron
      index=i[0]
      width=IRON[index][2]
      height=IRON[index][3]
      pattern=IRON[index][4]
      next if posx<i[1] || posx>=(i[1]+width)
      next if posy<i[2] || posy>=(i[2]+height)
      dx=posx-i[1]
      dy=posy-i[2]
      return true if pattern[dx+dy*width]>0
    end
    return false
  end

  def pbCheckRevealed
    ret=[]
    for i in 0...@items.length
      next if @items[i][3]
      revealed=true
      index=@items[i][0]
      width=ITEMS[index][4]
      height=ITEMS[index][5]
      pattern=ITEMS[index][6]
      for j in 0...height
        for k in 0...width
          layer=@sprites["tile#{@items[i][1]+k+(@items[i][2]+j)*BOARDWIDTH}"].layer
          revealed=false if layer>0 && pattern[k+j*width]>0
          break if !revealed
        end
        break if !revealed
      end
      ret.push(i) if revealed
    end
    return ret
  end

  def pbFlashItems(revealed)
    return if revealed.length<=0
    revealeditems = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    halfFlashTime = Graphics.frame_rate/8
    alphaDiff = (255.0/halfFlashTime).ceil
    for i in 1..halfFlashTime*2
      for index in revealed
        burieditem=@items[index]
        revealeditems.bitmap.blt(16*burieditem[1],32+16*burieditem[2],
           @itembitmap.bitmap,
           Rect.new(16*ITEMS[burieditem[0]][2],16*ITEMS[burieditem[0]][3],
           16*ITEMS[burieditem[0]][4],16*ITEMS[burieditem[0]][5]))
        if i>halfFlashTime
          revealeditems.color = Color.new(255,255,255,(halfFlashTime*2-i)*alphaDiff)
        else
          revealeditems.color = Color.new(255,255,255,i*alphaDiff)
        end
      end
      update
      Graphics.update
    end
    revealeditems.dispose
    for index in revealed
      @items[index][3]=true
      item=getConst(PBItems,ITEMS[@items[index][0]][0])
      @itemswon.push(item)
    end
  end

  def pbMain
    pbSEPlay("Mining ping")
    pbMessage(_INTL("Something pinged in the wall!\n{1} confirmed!",@items.length))
    loop do
      update
      Graphics.update
      Input.update
      next if @sprites["cursor"].isAnimating?
      # Check end conditions
      if @sprites["crack"].hits>=43
        @sprites["cursor"].visible=false
        pbSEPlay("Mining collapse")
        collapseviewport=Viewport.new(0,0,Graphics.width,Graphics.height)
        collapseviewport.z=99999
        @sprites["collapse"]=BitmapSprite.new(Graphics.width,Graphics.height,collapseviewport)
        collapseTime = Graphics.frame_rate*8/10
        collapseFraction = (Graphics.height.to_f/collapseTime).ceil
        for i in 1..collapseTime
          @sprites["collapse"].bitmap.fill_rect(0,collapseFraction*(i-1),
             Graphics.width,collapseFraction*i,Color.new(0,0,0))
          Graphics.update
        end
        pbMessage(_INTL("The wall collapsed!"))
        break
      end
      foundall=true
      for i in @items
        foundall=false if !i[3]
        break if !foundall
      end
      if foundall
        @sprites["cursor"].visible=false
        pbWait(Graphics.frame_rate*3/4)
        pbSEPlay("Mining found all")
        pbMessage(_INTL("Everything was dug up!"))
        break
      end
      # Input
      if Input.trigger?(Input::UP) || Input.repeat?(Input::UP)
        if @sprites["cursor"].position>=BOARDWIDTH
          pbSEPlay("Mining cursor")
          @sprites["cursor"].position-=BOARDWIDTH
        end
      elsif Input.trigger?(Input::DOWN) || Input.repeat?(Input::DOWN)
        if @sprites["cursor"].position<(BOARDWIDTH*(BOARDHEIGHT-1))
          pbSEPlay("Mining cursor")
          @sprites["cursor"].position+=BOARDWIDTH
        end
      elsif Input.trigger?(Input::LEFT) || Input.repeat?(Input::LEFT)
        if @sprites["cursor"].position%BOARDWIDTH>0
          pbSEPlay("Mining cursor")
          @sprites["cursor"].position-=1
        end
      elsif Input.trigger?(Input::RIGHT) || Input.repeat?(Input::RIGHT)
        if @sprites["cursor"].position%BOARDWIDTH<(BOARDWIDTH-1)
          pbSEPlay("Mining cursor")
          @sprites["cursor"].position+=1
        end
      elsif Input.trigger?(Input::A)   # Change tool mode
        pbSEPlay("Mining tool change")
        newmode=(@sprites["cursor"].mode+1)%2
        @sprites["cursor"].mode=newmode
        @sprites["tool"].src_rect.set(newmode*40,0,40,40)
        @sprites["tool"].y=176-72*newmode
      elsif Input.trigger?(Input::C)   # Hit
        pbHit
      elsif Input.trigger?(Input::B)   # Quit
        break if pbConfirmMessage(_INTL("Are you sure you want to give up?"))
      end
    end
    pbGiveItems
  end

  def pbGiveItems
    if @itemswon.length>0
      for i in @itemswon
        if $PokemonBag.pbStoreItem(i)
          pbMessage(_INTL("One {1} was obtained.\\se[Mining item get]\\wtnp[30]",
             PBItems.getName(i)))
        else
          pbMessage(_INTL("One {1} was found, but you have no room for it.",
             PBItems.getName(i)))
        end
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



class MiningGame
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbMain
    @scene.pbEndScene
  end
end



def pbMiningGame
  pbFadeOutIn {
    scene = MiningGameScene.new
    screen = MiningGame.new(scene)
    screen.pbStartScreen
  }
end
