pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--the life of ren
--developed by:
--sam albanese, oliver meyer,
--and michael shively

--github.com/samalby/tlor
-->8
--basic functions
function _draw()
 cls()
 palbrite(brightness)
 if intro then intro_draw()
 elseif combat then draw_combat()
 elseif dialogue then 
  p.animate(p)
  draw_game()
  draw_dia_menu()
 elseif main_menu then
  draw_menu() 
  spr(74,40,30,6,2)
  print("developed by: ",9,47,5)
  print("              sam albanese",5,47,5)
  print("              oliver meyer",5,53,5)
  print("              michael shively",5,59,5)
  draw_particles()
 else draw_game()
 end
 if (reading and not intro) tb_draw()
 if t>0 and t<1.2 then 
  ss_horizbars()
 elseif t>0 and t<10 then
  ss_vertbars()
 end
end

function _update60()
 t=time()-swapstart
 
 if fading then updatefade()
 elseif intro then intro_update()
 elseif combat then update_combat()
 elseif reading then tb_update()
 elseif main_menu or dialogue then update_menu()
 else update_game()
 end
end

function _init()
 playerattacked=false
 skipend=false
 changevoice=-1
 continuemusic=false
 attacking=false
 swapstart=-10
 music(0,10000)
 cam_x=0
 cam_y=0
 init_particles()
 fading=false
 brightness=6
 fadecoeff=-1
 fadecount=0
 sub_mode=0
 main_menu=true
 init_menu(0,60,{"start","controls","exit"})
end

function ss_horizbars()
    --draw black bars
    local a=0
    for y=cam_y,cam_y+127 do
     a=t*59
        if y%2==0 then
            line(cam_x+127,y,cam_x+127-a,y,0)
        else
            line(cam_x+0,y,cam_x+a,y,0)
        end
    end   
   
    --copy data from screen left/right
    for y=0,127 do
        local scr=0x6000+(y*64)
        if y%2==0then
            memcpy(scr,scr+t*30,64)
        else
            memcpy(scr,scr-t*30,64)
        end
    end   
end

function ss_vertbars()
    local a=0
    for x=cam_x,cam_x+127 do
        a=(2.2*120)-t*120
        if x%2==0 then
            line(x,cam_y-1,x,cam_y+a,0)
        else
            line(x,cam_y+128,x,cam_y+127-a,0)
        end
    end
end
-->8
--menu
--code borrowed from lexaloffle user pixelcod
function lerp(startv,endv,per)
 return(startv+per*(endv-startv))
end

function update_cursor()
 if (btnp(2)) m.sel-=1 cx=m.x sfx(0)
 if (btnp(3)) m.sel+=1 cx=m.x sfx(0)
 if (btnp(4)) cx=m.x sfx(1)
 if (btnp(5)) sfx(2)
 if (m.sel>m.amt) m.sel=1
 if (m.sel<=0) m.sel=m.amt
 
 cx=lerp(cx,m.x+5,0.5)
end

function draw_options()
 for i=1, m.amt do
  oset=i*8
  if i==m.sel then
   rectfill(cx,m.y+oset-1,cx+36,m.y+oset+5,col1)
   print("🅾️",cx+108,m.y+oset,0)
   print(m.options[i],cx+2,m.y+oset,col2)
  else
   print(m.options[i],m.x+2,m.y+oset,col1)
  end
 end
end

function draw_dia_options()
 p.draw(p)
 for i=1, m.amt do
  oset=i*6.40
  if i==m.sel then
   rectfill(cx,m.y+oset-1,cx+116,m.y+oset+5,col1)
   print("🅾️",cx+108,m.y+oset,0)
   print(m.options[i],cx+1,m.y+oset,col2)
  else
   print(m.options[i],m.x,m.y+oset,col1)
  end
 end
end

function init_menu(xoff,yoff,opt)
 m={}
 m.x=xoff
 cx=m.x
 m.y=yoff
 m.options=opt
 m.amt=0
 for i in all(m.options) do
  m.amt+=1
 end
 m.sel=1
 menu_timer=0
 pals={{7,0},{15,1},{6,5},
			   {10,8},{7,3},{7,2}}
 palnum=1
end

function update_menu()
 update_cursor()
 if sub_mode==0 then
  if btnp(4) and
  menu_timer>1 then
   if m.options[m.sel]=="start" then
    intro_init()
    music(-1)
   end
   if m.options[m.sel]=="controls" then
  	 tb_init(1,{"on pc,\n   🅾️ stands for z, and\n   ❎ stands for x.","use the ⬆️⬇️⬅️➡️ controls to\nmove ren, use 🅾️ to select, and\n❎ to go back.","for dialogue, you can use the \n❎ button to skip text, and the \n🅾️ to continue."},0,106)
  	end
  	if m.options[m.sel]=="exit" then
  	 extcmd("shutdown")
    end
  end
 end
 if sub_mode==1 then
  talkingto.talked=true
  m.options = {}
  m.amt=1
  add(m.options,talkingto.options[1][talkingto.stages[1]])
  if(#talkingto.options>1) m.amt=2 add(m.options,talkingto.options[2][talkingto.stages[2]])
  if(#talkingto.options>2) m.amt=3 add(m.options,talkingto.options[3][talkingto.stages[3]])
  if btnp(4) and menu_timer>1 then
   if m.options[m.sel]=="*exit*" then dialogue=false
   else tb_init(talkingto.voice,handle_response(talkingto.options[m.sel][talkingto.stages[m.sel]]),cam_x,cam_y+106)
    if(talkingto.name != "cara" and talkingto.name != "gnome") then talkingto.update_choice(talkingto,m.options[m.sel])
    elseif(talkingto.stages[m.sel]<count(talkingto.options[m.sel])) then talkingto.stages[m.sel]+=1
    end
   end
  end
 end
 if sub_mode==2 then
  if btnp(4) and menu_timer>1 then
   if m.options[m.sel]=="hug" then
  	 tb_init(1,{"you ran up to give klanky a hug","what the- hey!\noh.. thanks kid."},cam_x,cam_y+106) changevoice=2 fighter.favor+=5
     playerattacked=true
   end
   if m.options[m.sel]=="high-five" then
  	 tb_init(1,{"you put your hand up to \ngive klanky a high five!","... he left you hanging."},cam_x,cam_y+106) fighter.favor+=2
     playerattacked=true
   end
   if m.options[m.sel]=="hurt" then
  	 tb_init(1,{"you told klanky that his arms \nlook dumb.","wh- hey! nuh uh!"},cam_x,cam_y+106) changevoice=2 fighter.favor-=5
     playerattacked=true
   end
   if m.options[m.sel]=="bribe" then
  	 tb_init(1,{"you started flashing stacks","he flashes racks right back!","very impressive...\n\nfor a pipsqueak!"},cam_x,cam_y+106) changevoice=4 fighter.favor+=2
     playerattacked=true
   end
   if m.options[m.sel]=="brag" then
  	 tb_init(1,{"you gloated about still having \nyour lower jaw.","hey! that was a traumatic \nexperience! not cool!"},cam_x,cam_y+106) changevoice=4 fighter.favor-=5
     playerattacked=true
   end
   if m.options[m.sel]=="beatbox" then
  	 pdmg=2 tb_init(1,{"you started beatboxing.","cranky starts beatboxing too!","a full-blown beatbox battle\nensues before your superior\nvibrations knock him down!","you dealt 2 damage!","well, well... you can beatbox,\nbig deal!"},cam_x,cam_y+106) fighter.favor+=5 changevoice=4
     playerattacked=true
   end
   if m.options[m.sel]=="poke" then
    enemydmg=flr(rnd(talkingto.attackpower)+1)
  	tb_init(1,{"you walk forward and \npoke cara.","cara attacks you!","you took "..enemydmg.." points of damage."},cam_x,cam_y+106) 
    playerattacked=true
   end
   if m.options[m.sel]=="plead" then
  	tb_init(1,{"you plead with cara to \nstop being evil.","...she gives no response."},cam_x,cam_y+106) fighter.favor+=2
    playerattacked=true
   end
   if m.options[m.sel]=="question" then
  	tb_init(1,{"you begin to ask cara a\nquestion.","i'm not your tutorial bot\nanymore! enough games!"},cam_x,cam_y+106) fighter.favor-=2
    playerattacked=true
   end
   if m.options[m.sel]=="attack" then
    if(attack(p,talkingto)) then pdmg=flr(rnd(p.attackpower)+1) tb_init(1,{"you attacked "..talkingto.name.." and...","you hit!","you dealt "..pdmg.." points of damage!"},cam_x,cam_y+106)
    else tb_init(1,{"you attacked "..talkingto.name.." and...","you missed!"},cam_x,cam_y+106) 
    end
    playerattacked=true
   end
   if m.options[m.sel]=="reason" then
  	 if(attack(p,talkingto)) then pdmg=flr(rnd(p.attackpower)+1) tb_init(1,{"you attempted to reason with \n"..talkingto.name.." and..","they seem to be affected"},cam_x,cam_y+106) fighter.favor+=2
     else tb_init(1,{"you attempted to reason with "..talkingto.name.." and...","you failed."},cam_x,cam_y+106) tb_init(talkingto.voice,{""},cam_x,cam_y+106) 
     end
     playerattacked=true
   end
   if m.options[m.sel]=="action" then
  	 m.options=talkingto.actions
     menu_timer+=1
   end
  end
  if(btnp(❎) and menu_timer>1) m.options={"attack","reason","action"}
 end
 col1=pals[palnum][1]
 col2=pals[palnum][2]
 menu_timer+=1
end


function draw_menu()
 draw_options()
end

function draw_dia_menu()
 if dialogue then
  rectfill(tb.x,tb.y,tb.x+tb.w,tb.y+tb.h,tb.col1) -- draw the background.
  rect(tb.x,tb.y,tb.x+tb.w,tb.y+tb.h,tb.col2) -- draw the border.
  draw_dia_options()
 end
end

-->8
--game
function update_game()
 p.update(p) -- anims & movement
 update_npcs()
 update_switches()
 end

function draw_game()
 camera_update()
 map(0)
 draw_switches()
 p.draw(p)
 draw_npcs()
end

function init_game()
 main_menu=false
 reading=false
 dialogue=false
 init_npcs()
 talkingto=cara
 init_stages()
 currstage=stages.mechmedics
 camera_update()
end

scene={
 startx=0,
 starty=0,
 finishx=0,
 finishy=0
}

function draw_particles()
	-- particles
  foreach(particles, function(q)
    q.x += q.spd
    q.y += sin(q.off)
    q.off+= min(0.05,q.spd/32)/2
    rectfill(q.x+cam_x,q.y+cam_y,q.x+cam_x+q.s,q.y+cam_y+q.s,q.c)
    if q.x>128+4 then 
      q.x=-4
      q.y=rnd(128)
    end
  end)

  -- dead particles
  foreach(dead_particles, function(q)
    q.x += q.spd.x
    q.y += q.spd.y
    q.t -=1
    if q.t <= 0 then del(dead_particles,q) end
    rectfill(q.x-q.t/5,q.y-q.t/5,q.x+q.t/5,q.y+q.t/5,14+q.t%2)
  end)
end

function init_particles()
  particles = {}
  for i=0,64 do
    add(particles,{
    x=rnd(128)+cam_x,
    y=rnd(128)+cam_y,
    s=0+flr(rnd(5)/4),
    spd=.00001+rnd(5),
    off=rnd(1),
    c=6+flr(0.5+rnd(1))
    })
  end
  dead_particles = {}
end
-->8
--player
p={ --player table
 x=100, --key for horiz.
 y=60, --key for vert.
 dy=0, --key for horiz. vector
 dx=0, --key for vert. vector
 w=16,
 h=16,
 health=10,
 armorclass=15,
 attackpower=4,
 speed=.75,
 anim_time=0,
 anim_wait=0.30,
 stage=0, --numerical sprite modifier
 flipped=true,
 hitbox={x=0,y=0,w=15,h=15},
 anim_state=0,
 state="idle", --string describing animation
 draw=function(self)
  if(reading) self.state="idle"
  if(not fading) self.animate(self)
  if(self.flipped)
  then
   spr(self.anim_state,self.x,self.y,2,2,true,false)
  else
   spr(self.anim_state,self.x,self.y,2,2,false,false)
  end
 end,
 update=function(self)
  local colliding=false
  p.dx=0
  p.dy=0
  if btn(0) then 
   p.dx-=1*p.speed
   p.flipped=true
   p.state="runside"
  end 
  if btn(1) then 
   p.dx+=1*p.speed 
   p.flipped=false
   p.state="runside"
  end
  if btn(2) then 
   p.dy-=1*p.speed
   p.state="runup"
  end 
  if btn(3) then 
   p.dy+=1*p.speed
   p.state="rundown"
  end
  if p.dx==0 and p.dy==0
  then 
   p.state="idle"
  end
  
  --collisions             
  if (npcs_colliding()) colliding=true
  if (p.x==0 and p.dx!=0) colliding=true
  
  --more collisions
  if (p.dx!=0) then
   --tb_init(1,{"woops! the game developer\nhasn't finished this area yet!","come back later, mkay? ;)"},cam_x,cam_y+106)
   if (hitx(1,p.x+p.dx,p.y,p.w,p.h) or hity(1,p.x+p.dx,p.y,p.w,p.h)) continuemusic=false switch_stage(stages.outside) stages.maze.px=8 stages.maze.py=204 stages.gnomeland.px=520 stages.gnomeland.py=152
   if (hitx(2,p.x+p.dx,p.y,p.w,p.h) or hity(2,p.x+p.dx,p.y,p.w,p.h)) continuemusic=false switch_stage(stages.mechmedics)
   if (hitx(3,p.x+p.dx,p.y,p.w,p.h) or hity(3,p.x+p.dx,p.y,p.w,p.h)) continuemusic=false switch_stage(stages.maze) stages.outside.px=469 stages.outside.py=112
   if (hitx(4,p.x+p.dx,p.y,p.w,p.h) or hity(4,p.x+p.dx,p.y,p.w,p.h)) continuemusic=true switch_stage(stages.maze2) stages.maze.px=224 stages.maze.py=232
   if (hitx(5,p.x+p.dx,p.y,p.w,p.h) or hity(5,p.x+p.dx,p.y,p.w,p.h)) continuemusic=false switch_stage(stages.gnomeland) stages.outside.px=776 stages.outside.py=112
   if (hitx(6,p.x+p.dx,p.y,p.w,p.h) or hity(6,p.x+p.dx,p.y,p.w,p.h)) continuemusic=false switch_stage(stages.finalroom) stages.outside.px=1000 stages.outside.py=80
   if (hitx(7,p.x+p.dx,p.y,p.w,p.h) or hity(7,p.x+p.dx,p.y,p.w,p.h)) continuemusic=true switch_stage(stages.gnomeland2) stages.gnomeland.px=656 stages.gnomeland.py=248
   if (colliding or hitx(0,p.x+p.dx,p.y,p.w,p.h) or hity(0,p.x+p.dx,p.y,p.w,p.h)) p.dx=0
  end
  if (p.dy!=0) then
   if (hitx(1,p.x,p.y+p.dy,p.w,p.h) or hity(1,p.x,p.y+p.dy,p.w,p.h)) continuemusic=false switch_stage(stages.outside) stages.maze.px=8 stages.maze.py=204 stages.gnomeland.px=520 stages.gnomeland.py=152
   if (hitx(2,p.x,p.y+p.dy,p.w,p.h) or hity(2,p.x,p.y+p.dy,p.w,p.h)) continuemusic=false switch_stage(stages.mechmedics)
   if (hitx(3,p.x,p.y+p.dy,p.w,p.h) or hity(3,p.x,p.y+p.dy,p.w,p.h)) continuemusic=false switch_stage(stages.maze) stages.outside.px=469 stages.outside.py=112
   if (hitx(4,p.x,p.y+p.dy,p.w,p.h) or hity(4,p.x,p.y+p.dy,p.w,p.h)) continuemusic=true switch_stage(stages.maze2) stages.maze.px=224 stages.maze.py=232
   if (hitx(5,p.x,p.y+p.dy,p.w,p.h) or hity(5,p.x,p.y+p.dy,p.w,p.h)) continuemusic=false switch_stage(stages.gnomeland) stages.outside.px=776 stages.outside.py=112
   if (hitx(6,p.x,p.y+p.dy,p.w,p.h) or hity(6,p.x,p.y+p.dy,p.w,p.h)) continuemusic=false switch_stage(stages.finalroom) stages.outside.px=1000 stages.outside.py=80
   if (hitx(7,p.x,p.y+p.dy,p.w,p.h) or hity(7,p.x,p.y+p.dy,p.w,p.h)) continuemusic=true switch_stage(stages.gnomeland2) stages.gnomeland.px=656 stages.gnomeland.py=248
   if (colliding or hity(0,p.x,p.y+p.dy,p.w,p.h) or hitx(0,p.x,p.y+p.dy,p.w,p.h)) p.dy=0
  end
  p.x+=p.dx
  p.y+=p.dy
 end,
 animate=function(self)
  if(time()-self.anim_time>self.anim_wait)
  then 
   self.stage+=2
   self.anim_time=time()
   if self.stage>6
   then 
   self.stage=0
   end
  end
  if self.state=="idle"
  then self.anim_state=0+self.stage 
  elseif self.state=="runside"
  then self.anim_state=8+self.stage
  elseif self.state=="runup"
  then self.anim_state=40+self.stage
  elseif self.state=="rundown"
  then self.anim_state=32+self.stage
  end
 end
}
-->8
--npcs
function init_npcs()
 --cara
 cara={
   name="cara",
   talked=false,
   x=188,
   y=42,
   dx=0,
   dy=0,
   w=16,
   h=16,
   anim_wait=0.15,
   anim_time=0,
   anim_state="idle",
   state=64,
   stage=0,
   voice=1,
   flipped=true,
   options={
    {"who are you?","carebot?","how do you pronounce cara?"," "},
    {"where am i?","mechmedics?","spring city?","used to be?"," "},
    {"how long was i out?","i can't remember anything!","can you fix it?","where can i find the parts?","*exit*"}
   },
   stages={1,1,1},
   draw=function(self)
    spr(self.state,self.x,self.y,2,2,self.flipped,false)
    if nearactor(p,self)
    then
     if(reading) then if(not donetalking) self.animate(self)
     else 
      spr(96,self.x+7,self.y-9,2,2,false,false)
      print('🅾️', self.x+14, self.y-8,1)
     end
    end
   end,
   update=function(self)
    if nearactor(p,self) then
     if (btnp(4)) then
      handle_dialogue("cara")
     end
    end
   end,
   animate=function(self)
    if(p.x < self.x) then self.flipped=true
    else self.flipped=false end
    if (time()-self.anim_time>self.anim_wait)
    then 
     self.stage+=4
     self.anim_time=time()
    if (self.stage>4) self.stage=0
    end
    self.state=64+self.stage
   end
 }

 evilcara={
   name="evilcara",
   talked=false,
   x=992,
   y=208,
   dx=0,
   dy=0,
   w=16,
   h=16,
   --combat stuff
   favor=0,
   sparetext={"why won't you just fight me?","i'm literally evil!","i'm... evil?","what is going on?\nwhy did it happen this way?","thank you for sparing me,\nbut i think it's best if\ni just shut down.","goodbye."},
   reasondc=17, --difficulty to reason with (d20 has to hit at or above this)
   actions={"poke","plead","question"}, --options when pressing the action button during combat
   health=25, --hp, self explanatory
   armorclass=16, --dnd ac
   attackpower=6, --time between next animation update
   anim_wait=0.4, --living variable storing time() iterations for updating animations
   anim_time=0,
   anim_wait=0.15,
   anim_time=0,
   anim_state="idle",
   state=106,
   stage=0,
   voice=1,
   flipped=true,
   options={
    {"hwut"," "},
    {"bad?"," "},
    {"evil?"," "}
   },
   stages={1,1,1},
   draw=function(self)
    if(not beatup) spr(106,self.x,self.y,2,2,self.flipped,false)
    if(beatup) spr(66,self.x,self.y,2,2,self.flipped,false)
    if nearactor(p,self)
    then
     if(not reading) 
     then 
      if(not beatup and not combat) then
       spr(96,self.x+7,self.y-9,2,2,false,false)
       print('🅾️', self.x+14, self.y-8,1)
      end
     end
    end
   end,
   update=function(self)
    if(self.talked) self.beatup=true
    if nearactor(p,self) then
     if (btnp(4)) then
      handle_dialogue("evilcara")
     end
    end
   end,
   animate=function(self)
   end
 }

 klanky={
   name="klanky",
   talked=false,
   --position variables
   x=648,
   y=48,
   dx=0,
   dy=0,
   --width and height in pixels for collisions
   w=16,
   h=16,
   --combat stuff
   favor=0,
   sparetext={"you know, kid...","i was gonna tear you up\nfor scrap, but something\nseems different about you.","i think we can set aside\nour differences.","thanks, kid."},
   reasondc=15, --difficulty to reason with (d20 has to hit at or above this)
   actions={"hug","high-five","hurt"}, --options when pressing the action button during combat
   health=5, --hp, self explanatory
   armorclass=11, --dnd ac
   attackpower=2, --time between next animation update
   anim_wait=0.4, --living variable storing time() iterations for updating animations
   anim_time=0,
   beatup=false,
   state=70, --sprite number for the character
   stage=0, --modifier that progresses animation
   voice=2, --sfx tag for sound when they speak
   flipped=false, --whether to flip the sprite or not
   options={ --living table that updates through the progression of dialogue
    {"parts?"," "},
    {"why do you look like that?"," "},
    {"*attack him*"," "}
   },
   stages={1,1,1}, --stages table from cara dialogue, required for compatibility
   draw=function(self) --draw function that runs every _draw iteration
    if(not self.beatup) spr(self.state,self.x,self.y,2,2,self.flipped,false)
    if(self.beatup) spr(self.state,self.x,self.y,2,1,self.flipped,false)
    if nearactor(p,self)
    then
     self.animate(self)
     if(reading) then if(not donetalking) self.animate(self)
     else
      spr(96,self.x+7,self.y-9,2,2,false,false)
      print('🅾️', self.x+14, self.y-8,1)
     end
    end
   end,
   update=function(self) --update function that runs every _update iteration
    if nearactor(p,self) then
     if (btnp(4)) then
      handle_dialogue("klanky")
     end
    end
   end,
   animate=function(self)
    if(p.x <= self.x) then self.flipped=true
    else self.flipped=false end
    if(not self.beatup) then
     if (time()-self.anim_time>self.anim_wait)
     then 
      self.stage+=2
      self.anim_time=time()
     if (self.stage>2) self.stage=0
     end
      self.state=70+self.stage
    else
     if (time()-self.anim_time>self.anim_wait)
     then 
      self.stage+=16
      self.anim_time=time()
     if (self.stage>16) self.stage=0
     end
      self.state=110+self.stage
    end
   end,
   update_choice=function(self,ch)
    if(ch=="chrono-encryption unit?") dialogue=false
    if(ch=="*attack him*") dialogue=false precombat=true
    if(ch=="i'm sure") dialogue=false precombat=true
    if(ch=="*step back*") dialogue=false precombat=true
    if(ch=="not from a murderer!") dialogue = false precombat=true
    if(ch=="parts?") self.options={{"i'd like to place an order!"," "},{"i'm not interested"," "}}
    if(ch=="why do you look like that?") self.options={{"parts?"," "},{"not from a murderer!"," "},{"who do you take from?"," "}}
    if(ch=="i'm not interested") self.options={{"chrono-encryption unit?"," "},{"i'm sure"," "}}
    if(ch=="quantum data matrix?") self.options={{"chrono-encryption unit?"," "},{"i'm not interested"," "}}
    if(ch=="who do you take from?") self.options={{"i'd like to place an order!"," "},{"mostly?"," "},{"*step back*"," "}}
    if(ch=="i'd like to place an order!") self.options={{"chrono-encryption unit?"," "},{"quantum data matrix?"," "}}
    if(ch=="mostly?") self.options={{"i'd like to place an order!"," "},{"i'm not interested"," "}}
   end
 }

  cranky={
   name="cranky",
   talked=false,
   --position variables
   x=448,
   y=318,
   dx=0,
   dy=0,
   --width and height in pixels for collisions
   w=16,
   h=16,
   --combat stuff
   favor=0,
   sparetext={"i don't say this very often,\nbut man, i'm impressed.","let's just wrap this whole \nthing up, yeah?"},
   reasondc=15, --difficulty to reason with (d20 has to hit at or above this)
   actions={"bribe","brag","beatbox"}, --options when pressing the action button during combat
   health=10, --hp, self explanatory
   armorclass=14, --dnd ac
   attackpower=4, --time between next animation update
   anim_wait=0.4, --living variable storing time() iterations for updating animations
   anim_time=0,
   beatup=false,
   state=100, --sprite number for the character
   stage=0, --modifier that progresses animation
   voice=4, --sfx tag for sound when they speak
   flipped=false, --whether to flip the sprite or not
   options={ --living table that updates through the progression of dialogue
    {"yup, suck it nerd"," "},
    {"wasn't hard at all"," "},
    {"took me awhile"," "}
   },
   stages={1,1,1}, --stages table from cara dialogue, required for compatibility
   draw=function(self) --draw function that runs every _draw iteration
    if(not self.beatup) spr(self.state,self.x,self.y,2,2,self.flipped,false)
    if(self.beatup) spr(self.state,self.x,self.y,2,1,self.flipped,false)
    if nearactor(p,self)
    then
     self.animate(self)
     if(reading) then if(not donetalking) self.animate(self)
     elseif(not combat) then
      spr(96,self.x+7,self.y-9,2,2,false,false) -- draw text bubble
      print('🅾️', self.x+14, self.y-8,1)
     end
    end
   end,
   update=function(self) --update function that runs every _update iteration
    if nearactor(p,self) then
     if (btnp(4)) then
      handle_dialogue("cranky")
     end
    end
   end,
   animate=function(self)
    if(p.x >= self.x) then self.flipped=true
    else self.flipped=false end
    if(not self.beatup) then
     if (time()-self.anim_time>self.anim_wait)
     then 
      self.stage+=2
      self.anim_time=time()
     if (self.stage>2) self.stage=0
     end
      self.state=100+self.stage
    else
     if (time()-self.anim_time>self.anim_wait)
     then 
      self.stage+=16
      self.anim_time=time()
     if (self.stage>16) self.stage=0
     end
      self.state=108+self.stage
    end
   end,
   update_choice=function(self,ch)
    if(ch=="yup, suck it nerd") dialogue=false precombat=true
    if(ch=="wasn't hard at all") self.options={{"i need parts"," "},{"i'm sooo awesome"," "},{"you're ugly"," "}}
    if(ch=="took me awhile") self.options={{"chrono-encryption unit"," "}}
    if(ch=="i need parts") self.options={{"chrono-encryption unit"," "}}
    if(ch=="i'm sooo awesome") self.options={{"chrono-encryption unit"," "}}
    if(ch=="you're ugly") dialogue=false precombat=true
    if(ch=="chrono-encryption unit") self.options={{"i'm open to work"," "},{"kill you for it"," "}}
    if(ch=="i'm open to work") dialogue=false
    if(ch=="kill you for it") self.favor=-1000 dialogue=false precombat=true skipend=true
   end
  }
   
  gnome={
   name="gnome",
   talked=false,
   --position variables
   x=509,
   y=291,
   dx=0,
   dy=0,
   --width and height in pixels for collisions
   w=16,
   h=16,
   --combat stuff
   favor=0,
   reasondc=15, --difficulty to reason with (d20 has to hit at or above this)
   actions={"bribe","brag","beatbox"}, --options when pressing the action button during combat
   health=10, --hp, self explanatory
   armorclass=14, --dnd ac
   attackpower=2, --time between next animation update
   anim_wait=0.4, --living variable storing time() iterations for updating animations
   anim_time=0,
   beatup=false,
   state=98, --sprite number for the character
   stage=0, --modifier that progresses animation
   voice=3, --sfx tag for sound when they speak
   flipped=false, --whether to flip the sprite or not
   options={ --living table that updates through the progression of dialogue
    {"got parts?","*exit*"," "},
    {"nice tunes","*exit*"," "},
    {"look like a gnome","*exit*"," "}
   },
   stages={1,1,1}, --stages table from cara dialogue, required for compatibility
   draw=function(self) --draw function that runs every _draw iteration
    spr(self.state,self.x,self.y,1,2,self.flipped,self.beatup)
    if nearactor(p,self)
    then
     self.animate(self)
     if(reading) then if(not donetalking) self.animate(self)
     else
      spr(96,self.x+7,self.y-9,2,2,false,false) -- draw text bubble
      print('🅾️', self.x+14, self.y-8,1)
     end
    end
   end,
   update=function(self) --update function that runs every _update iteration
    if nearactor(p,self) then
     if (btnp(4)) then
      handle_dialogue("gnome")
     end
    end
   end,
   animate=function(self)
    if(p.x <= self.x) then self.flipped=true
    else self.flipped=false end
    if (time()-self.anim_time>self.anim_wait)
    then 
     self.stage+=1
     self.anim_time=time()
     if (self.stage>1) self.stage=0
    end
    self.state=98+self.stage
   end,
   update_choice=function(self,ch)
   end
  }
  
  squeak={
   name="squeak",
   talked=true,
   --position variables
   x=208,
   y=168,
   dx=0,
   dy=0,
   --width and height in pixels for collisions
   w=8,
   h=8,
   --combat stuff
   favor=0,
   reasondc=15, --difficulty to reason with (d20 has to hit at or above this)
   actions={"bribe","brag","beatbox"}, --options when pressing the action button during combat
   health=10, --hp, self explanatory
   armorclass=14, --dnd ac
   attackpower=2, 
   anim_wait=0.4, --time between next animation update
   anim_time=0, --living variable storing time() iterations for updating animations
   beatup=false,
   state=120, --sprite number for the character
   stage=0, --modifier that progresses animation
   voice=3, --sfx tag for sound when they speak
   flipped=false, --whether to flip the sprite or not
   options={ --living table that updates through the progression of dialogue
    {":)"," "},
   },
   stages={1,1,1}, --stages table from cara dialogue, required for compatibility
   draw=function(self) --draw function that runs every _draw iteration
    spr(self.state,self.x,self.y,1,1,self.flipped,false)
    if nearactor(p,self)
    then
     self.animate(self)
     if(reading) then if(not donetalking) self.animate(self)
     else
      spr(96,self.x+7,self.y-9,2,2,false,false) -- draw text bubble
      print('🅾️', self.x+14, self.y-8,1)
     end
    end
   end,
   update=function(self) --update function that runs every _update iteration
    if nearactor(p,self) then
     if (btnp(4)) then
      handle_dialogue("squeak")
     end
    end
   end,
   animate=function(self)
    if(p.x <= self.x) then self.flipped=true
    if (time()-self.anim_time>self.anim_wait)
     then 
      self.stage+=1
      self.anim_time=time()
      if (self.stage>1) self.stage=0
     end
    self.state=120+self.stage
    end
   end,
   update_choice=function(self,ch)
   end
  }
end

function update_npcs()
 cara:update(cara)
 klanky:update(klanky)
 cranky:update(cranky)
 gnome:update(gnome)
 squeak:update(squeak)
 evilcara:update(evilcara)
end

function draw_npcs()
 cara:draw(cara)
 klanky:draw(klanky)
 cranky:draw(cranky)
 gnome:draw(gnome)
 squeak:draw(squeak)
 evilcara:draw(evilcara)
end

function npcs_colliding()
 local colliding
 if (hitactor(p,cara)) colliding=true
 if (hitactor(p,klanky)) colliding=true
 if (hitactor(p,cranky)) colliding=true
 if (hitactor(p,gnome)) colliding=true
 if (hitactor(p,squeak)) colliding=true
 if (hitactor(p,evilcara)) colliding=true
 return colliding
end

function handle_dialogue(c)
  local q = nil
  dialogue=true
  sub_mode=1
  if(c=="cara")then
   q = cara
   if(q.talked) then tb_init(1,{"i'm sure you'll find what \nyou're looking for!"},cam_x,cam_y+106)
   else 
    tb_init(1,{"hey you! you're finally\npowered on! i was getting\nworried, you know."},cam_x,cam_y+106) 
   end
  end
  if c=="klanky" then
   q = klanky
   if (q.talked) then tb_init(2,{"go on. scram, kid."},cam_x,cam_y+106)
   else tb_init(2,{"hey kid, wanna buy some parts?"},cam_x,cam_y+106) end
  end
  if c=="cranky" then
   q = cranky
   if (q.talked) then tb_init(4,{"get on outta here! \ni'm leakin oil!"},cam_x,cam_y+106)
   else tb_init(4,{"what the? how did you\nget in here?!","i could hardly solve that \npuzzle just to go drain the \noil!","you did it just like that?"},cam_x,cam_y+106) end
  end
  if c=="gnome" then
   q = gnome
   if (q.talked) then tb_init(4,{"cool... can you leave now?"},cam_x,cam_y+106)
   else tb_init(3,{"oh hey, somebody's in my house."},cam_x,cam_y+106) end
  end
  if c=="squeak" then
   q = squeak
   if (q.talked) then tb_init(3,{"what am i even supposed to be?","what is anything?","why are we even here?"},cam_x,cam_y+106) dialogue=false
   else tb_init(3,{"what am i even supposed to be?","what is anything?","why are we even here?"},cam_x,cam_y+106) dialogue=false end
  end
  if c=="evilcara" then
   q = evilcara
   music(-1)
   if (q.talked) then dialogue=false
   else tb_init(1,{"hello, it is i,","evil car-","wait hold on, one more time","evil cara! hahaa!!","you have travelled far, talked\nwith every npc possible\nand now, it is time...","for the final boss battle!","note:(just like every other\none, sorry not sorry :>)"},cam_x,cam_y+106) dialogue=false precombat=true end
  end
  talkingto=q
  if(talkingto.talked) then dialogue=false
  else init_menu(cam_x+2,cam_y+102,{q.options[1][q.stages[1]],q.options[2][q.stages[2]],q.options[3][q.stages[3]]}) end
end

function handle_response(sel)
  if(sel=="who are you?") return {"my name is cara.\ni am a carebot.\ni am here to help!"}
  if(sel=="where am i?") return {"you are in a mechmedics repair \nfacility, located in spring \ncity. you are safe."}
  if(sel=="how long was i out?") return {"well, i'm not sure how long you \nwere out there before i found \nyou, but you've been here for...","...almost 92 hours."} 
  if(sel=="carebot?") return {"that's right! my function is to \nrepair damaged inorganic units.","just like you!"} 
  if(sel=="mechmedics?") return {"yes... a repair facility for \nrobots.","we send daily patrols \nthroughout spring city \nto recover units in need."} 
  if(sel=="i can't remember anything!") return {"oh no...","i was afraid of this. \nwhile i was repairing you,","i noticed that your memory \ndrive has had some critically \ndamaged components."} 
  if(sel=="how do you pronounce cara?") return {"oh! car-a. like a car, because \ni'm a robot, you know?","care-a would be pretty on the \nnose. thanks for asking!","       **improve favor**"} 
  if(sel=="spring city?") return {"that's right!","spring city was established in \n2094 in what used to be \nthe american southwest.","it started as a small \ncollective of service droids.","together, they pooled \ntheir collective processing\npower to create a settlement."} 
  if(sel=="can you fix it?") return {"unfortunately, i don't have the \nrequired parts here with me.","resources are scarce."} 
  if(sel=="used to be?") return {'yeah!','of course, it was only \nconsidered "america" while \nthere were still humans.',"they've been gone for...","gosh...","decades now."} 
  if(sel=="where can i find the parts?") return {"well,","you'll need a new \nchrono-encryption unit \nand a quantum data matrix.","parts like those are hard \nto come by nowadays.","but, i'm sure they're able\nto be found someplace 'round here!"}
  if(sel=="parts?") return {"yessir! i've got all sorts! \nbig, small, old, new...","well, maybe not new. \nslightly used at best.","fair warning, \nany complex parts i'll need \nto put an order in for."}
  if(sel=="why do you look like that?") return {"oh... right.","i suppose my body has \nbecome a sort of patchwork quilt \nover the years.","as new parts stopped being \nmanufactured, i've had to resort \nto scavenging replacements for","worn out parts from \nother robots. ","interested in some parts?"}
  if(sel=="*attack him*") return {"huh? woah!"}
  if(sel=="i'm not interested") return {"hmm... are you sure?\nconsider carefully."}
  if(sel=="i'm sure") return {"well, \nas long as you're sure... ","you do realize you're \nonly useful for one \nthing now, right?"}
  if(sel=="chrono-encryption unit?") return {"wow, \nthose are in short supply \nthese days!","i can put an order \nin for it, but you'll have \nto do a favor for me."}
  if(sel=="quantum data matrix?") return {"oh... i actually don't \nhave a connect for those. ","can i interest you \nin anything else?"}
  if(sel=="not from a murderer!") return {"murderer?? ","i'll have you know \nall my parts are \nethically sourced! ","i'll fucking kill you!!"}
  if(sel=="who do you take from?") return {"anyone who gets close enough! ","ha ha. just kidding. ","i strip parts from robots \nthat are too worn out \nto function anymore.","mostly."}
  if(sel=="i'd like to place an order!") return {"lovely!","what part?"}
  if(sel=="mostly?") return {"listen bud,\ndon't ask questions.","are you buying or not?"}
  if(sel=="*step back*") return {"oop, get back here, you!"}
  if(sel=="yup, suck it nerd") return {"nerd?!","i'll show you who's the \nnerd!"}
  if(sel=="wasn't hard at all") return {"hmph... showboat","seeing as how you broke into \nmy house, why shouldn't i scrap \nyou for parts right now?"}
  if(sel=="took me awhile") return {"i know right?\ngame devs really popped off\nwith that one.","alright, what do you want?\ni'll let you off easy,\nyou seem polite."}
  if(sel=="i need parts") return {"alright...","well, i've got what you need\nthat's for sure","let's see here... i've got \neyeballs, lowballs, bowling balls, \noh wait.. wrong list","i've got... cybernetic arms,\nimplants, brains, legs,","even this nifty little\nmacguff- i mean...\nchrono-encryption unit!"}
  if(sel=="you're ugly") return {"yeah, real creative, guy","well, you asked for it"}
  if(sel=="chrono-encryption unit") return {"ah... well, you and everyone\nelse, pal. question is:","what are ya gonna pay for it?"}
  if(sel=="kill you for it") return {"woah... that took a dark turn.","hey- wh- back up pal!\nlet's think this thr-"}
  if(sel=="i'm open to work") return {"hmph...","well, now that you mention it,\ni could use some help.","outside of this building, there's\nanother building"}
  if(sel=="i'm sooo awesome") return {"come on, don't waste my time.\ngimme a better reason.\nwhat are you here for?"}
  if(sel=="got parts?") return {"uhh... no?","hey man, can you leave?\ni just live here."}
  if(sel=="nice tunes") return {"thanks... can you leave now?"}
  if(sel=="look like a gnome") return {"._.","please leave."}
  return sel
end
-->8
--collisions
function hitx(f,x,y,w,h)
 local collx=false
 for i=x,x+w-1,w-1 do
  if (fget(mget(i/8,y/8),f)) 
  or (fget(mget(i/8,(y+h-1)/8),f))
  then
   collx=true
  end
 end
 return collx 
end

function hity(f,x,y,w,h)
 local colly=false
 for i=y,y+h-1,h-1 do
  if (fget(mget(x/8,i/8),f)) 
  or (fget(mget((x+w-1)/8,i/8),f)) 
  then
   colly=true
  end
 end
 return colly
end

function hitactor(obj,other)
 if
  other.x+other.dx+other.w > obj.x+obj.dx and 
  other.y+other.dy+other.h > obj.y+obj.dy and
  other.x+other.dx < obj.x+obj.dx+obj.w and
  other.y+other.dy < obj.y+obj.dy+obj.h
 then
  return true
 end
 return false
end

function nearactor(obj,other)
 if
  other.x+other.w+5 > obj.x and 
  other.y+other.h+5 > obj.y and
  other.x < obj.x+obj.w+5 and
  other.y < obj.y+obj.h+5 
 then
  return true
 end
 return false
end
-->8
--text box 
function tb_init(voice,string,xoff,yoff) -- this function starts and defines a text box.
 donetalking=false
 reading=true -- sets reading to true when a text box has been called
 tb={ -- table containing all properties of the text box
 str=string, -- the strings
 voice=voice, -- the voice
 counter=0,
 othercount=0,
 i=1, -- index used to tell what string from tb.str to read
 cur=0, -- buffer used to progressively show characters on the text box
 char=0, -- current character to be drawn on the text box
 x=xoff, -- horizontal offset
 y=yoff, -- vertical offset
 w=127, -- text box width
 h=21, -- text box height
 col1=0, -- background color
 col2=7, -- border color
 col3=7, -- text color
 }
end

function tb_update()  -- this function handles the text box on every frame update.
 if(not main_menu) camera_update()
 if tb.char<#tb.str[tb.i] then -- if the message has not been processed until it's last character:
  donetalking=false
  if (tb.str[tb.i][tb.char]=="," or tb.str[tb.i][tb.char]=="." or tb.str[tb.i][tb.char]=="!") then tb.cur+=.05
  else tb.cur+=.8 -- increase the buffer. 0.5 is already max speed for this setup. if you want messages to show slower, set this to a lower number. this should not be lower than 0.1 and also should not be higher than 0.9
  end
  if tb.cur>0.9 then -- if the buffer is larger than 0.9:
   tb.char+=1 -- set next character to be drawn.
   tb.cur=0 -- reset the buffer.
   if (ord(tb.str[tb.i],tb.char)!=32) sfx(tb.voice) -- play the voice sound effect.
  end
  if (btnp(5)) tb.char=#tb.str[tb.i] -- advance to the last character, to speed up the message. 
 elseif btnp(4) or (#tb.str==tb.i and skipend) then -- if already on the last message character and button 🅾️/z is pressed: (or skipend has been tripped to skip player input)
  if #tb.str>tb.i then -- if the number of strings to display is larger than the current index (this means that there's another message to display next):
   if(tb.i+1==#tb.str and changevoice>0) tb.voice=changevoice changevoice=-1 --if on last message, change to the changevoice
   tb.i+=1 -- increase the index, to display the next message on tb.str
   tb.cur=0 -- reset the buffer.
   tb.char=0 -- reset the character position.
  else -- if there are no more messages to display:
   if(skipend) skipend=false
   if(exitcombat) exitcombat=false combat=false swapstart=time() music(currstage.entrymusic,5000)
   reading=false -- set reading to false. resumes normal gameplay.
   if(precombat) music(1) init_combat(talkingto) swapstart=time() 
   if combat then
    attacking=false
    defender.health-=enemydmg
    fighter.health-=pdmg
    pdmg=0
    enemydmg=0
    if(fighter.health<=0) then music(-1) sfx(10) exitcombat=true fighter.beatup=true talkingto.beatup=true tb_init(1,{"you won!"},cam_x,cam_y+106)
    elseif(fighter.favor>=10) then talkingto.talked=true music(-1) exitcombat=true tb_init(fighter.voice,fighter.sparetext,cam_x,cam_y+106)
    elseif(playerattacked) then player_turn=false playerattacked=false end
   end
  end
 else donetalking=true
 end
end

function tb_draw() -- this function draws the text box.
 if reading then -- only draw the text box if reading is true, that is, if a text box has been called and tb_() has already happened.
  rectfill(tb.x,tb.y,tb.x+tb.w,tb.y+tb.h,tb.col1) -- draw the background.
  rect(tb.x,tb.y,tb.x+tb.w,tb.y+tb.h,tb.col2) -- draw the border.
  print(sub(tb.str[tb.i],1,tb.char),tb.x+2,tb.y+2,tb.col3) -- draw the text.
  if(donetalking) then
   tb.counter+=1
   if(tb.counter>=30) print("🅾️",tb.x+118,tb.y+15,7)
   if(tb.counter==60) tb.counter=0
  end
 end
end

-->8
--camera
function camera_update()
 cam_x=p.x-60
 cam_y=p.y-60

 cam_x=mid(currstage.sx,cam_x,currstage.mx)
 cam_y=mid(currstage.sy,cam_y,currstage.my)

 --change the camera position
 camera(cam_x,cam_y)
end

function palbrite(b)
 local p,c,v="あつてとなにぬきのはこふへほのみああちつちちかあうおあえいてうお"pal()for i=b,5do for j=0,15do c=peek(24336+j)+1if(c>=129)c-=112
 v=ord(sub(p,c,c))-154if(v>=16)v+=112
 pal(j,v,1)end end 
end


function updatefade()
 fadecount+=1.5
 if(brightness==0) fadecount-=.55
 if fadecount > 10 then
  brightness+=fadecoeff
  fadecount=0
 end
 if brightness==0 then
  fadecoeff*=-1
  currstage=nextstage
  p.x=currstage.px
  p.y=currstage.py
  if(not continuemusic) music(-1)
 end
 if brightness==6 then
  fading=false
  fadecoeff*=-1
  if(not continuemusic) music(currstage.entrymusic)
 end
end

-->8
--map stages
function init_stages()
 switch_values=0
 switches_done=false
 stages={
  mechmedics={
    entrymusic=-1,
    px=320,
    py=72,
    sx=0,
    mx=208,
    sy=0,
    my=0,
  },
  outside={
    entrymusic=33,
    px=352,
    py=68,
    sx=352,
    mx=888,
    sy=0,
    my=0,
  },
  maze={
    entrymusic=16,
    px=8,
    py=208,
    sx=8,
    mx=112,
    sy=152,
    my=253,
  },
  maze2={
    entrymusic=16,
    px=256,
    py=224,
    sx=256, 
    mx=352,
    sy=152,
    my=248,
    switches={
      {x=296,y=184,w=4,h=8,sprite=222,value=0,dx=0,dy=0,s=4},
      {x=360,y=184,w=4,h=8,sprite=222,value=0,dx=0,dy=0,s=5},
      {x=296,y=248,w=4,h=8,sprite=222,value=0,dx=0,dy=0,s=1},
      {x=360,y=248,w=4,h=8,sprite=222,value=0,dx=0,dy=0,s=20}
    }
  },
  gnomeland={
    entrymusic=48,
    px=520,
    py=152,
    sx=496,
    mx=560,
    sy=128,
    my=136,
  },
  gnomeland2 ={
    entrymusic=48,
    px=656,
    py=288,
    sx=496,
    mx=560,
    sy=264,
    my=312,
  },
  finalroom={
    entrymusic=0,
    px=712,
    py=208,
    sx=704,
    mx=889,
    sy=136,
    my=152,
  }
 }
 currstage=stages.mechmedics
end

function draw_switches()
 foreach(stages.maze2.switches,function(q)
  spr(q.sprite,q.x,q.y)
  print(switch_values.."/18",321,217,7)
 end)
end

function update_switches()
 if(not switches_done) then
  switch_values=0
  foreach(stages.maze2.switches,function(q)
   if nearactor(p,q) then 
    if(btnp(🅾️)) q.value+=1
    if(q.value>1) q.value= -1
   end
   q.sprite=222+q.value
   switch_values+=q.s*q.value
  end)
  if(switch_values==18) sfx(10,-1,11) switches_done=true mset(40,34,210) mset(41,34,210) mset(42,34,210) mset(43,34,210)
 end
end

function switch_stage(stage)
 fadecount=0
 brightness=5
 sfx(5)
 fading=true
 updatefade()
 nextstage=stage
end

-->8
--intro scene
function intro_init()
 intro=true
 reading=true -- sets reading to true when a text box has been called
 intro_counter=0
 intro_donetalking = false
 intro_tb={ -- table containing all properties of the text box
 str={
  "",
  "system initialization...  start.\n\nmotor systems...          check.\ncentral processing...     check.\nenvironmental sensors...  check.\ndecision-making...        check.\nmemory functionality...   error.\n\n[error detected]",
  "scanning memory drive...",
  "**critical error**\n\nmemory drive failure.\n\nanomalies detected in memory.\n\ninitiating diagnostic...",
  "corrupted components detected...\n\nestimated system corruption...\n\n\n                         ...37%",
  "component malfunction detected.\n\nreplacement required.",
  "...initiating emergency boot..."
  }, -- the strings
 voice=4, -- the voice
 i=1, -- index used to tell what string from tb.str to read
 cur=0, -- buffer used to progressively show characters on the text box
 char=0, -- current character to be drawn on the text box
 x=0, -- horizontal offset
 y=5, -- vertical offset
 w=127, -- text box width
 h=21, -- text box height
 col1=0, -- background color
 col2=7, -- border color
 col3=7, -- text color
 }
end

function intro_update()  -- this function handles the text box on every frame update.
 if intro_tb.char<#intro_tb.str[intro_tb.i] then -- if the message has not been processed until it's last character:
  if (intro_tb.str[intro_tb.i][intro_tb.char]=="," or intro_tb.str[intro_tb.i][intro_tb.char]=="." or intro_tb.str[intro_tb.i][intro_tb.char]==":") then intro_tb.cur+=.05
  else intro_tb.cur+=2 end
  intro_donetalking=false
  if intro_tb.cur>0.9 then -- if the buffer is larger than 0.9:
   intro_tb.char+=1 -- set next character to be drawn.
   intro_tb.cur=0 -- reset the buffer.
   if (ord(intro_tb.str[intro_tb.i],intro_tb.char)!=32) sfx(intro_tb.voice) -- play the voice sound effect.
  end
  if (btnp(5)) intro_tb.char=#intro_tb.str[intro_tb.i] -- advance to the last character, to speed up the message.
 elseif btnp(4) then -- if already on the last message character and button 🅾️/z is pressed:
  if #intro_tb.str>intro_tb.i then -- if the number of strings to display is larger than the current index (this means that there's another message to display next):
   intro_tb.i+=1 -- increase the index, to display the next message on tb.str
   intro_tb.cur=0 -- reset the buffer.
   intro_tb.char=0 -- reset the character position.
  else -- if there are no more messages to display:
   intro=false
   reading=false -- set reading to false. resumes normal gameplay.
   init_game()
  end
 else intro_donetalking=true
 end
end

function intro_draw() -- this function draws the intro text
 if reading 
 then -- only draw the text box if reading is true, that is, if a text box has been called and tb_() has already happened.
  print(sub(intro_tb.str[intro_tb.i],1,intro_tb.char),intro_tb.x+2,intro_tb.y+2,intro_tb.col3) -- draw the text.
  if intro_donetalking
  then
   intro_counter+=1
   if(intro_counter>=30) print("🅾️",118,118,7)
   if(intro_counter==60) intro_counter=0
  end
 end
end

-->8
--combat
function draw_combat()
 if(t<=1.2) 
 then 
  if(not exitcombat) draw_game()
 else
  transition=false
  for i=-32,127,8 do
	  for j=-32,127,8 do
	   if(i%2==0) then 
	    if(j%2==0) then 
	     print("♥",cam_x+2*i+k,cam_y+2*j+k,1)
	     print("♥",cam_x+2*i+k+1,cam_y+2*j+k,2)
	    end
 	  end
 	 end
 	end
 defender.draw(defender)
 defender.animate(defender)
 fighter.draw(fighter)
 fighter.animate(fighter)
 end
 if(t>=2.4 and not transition) then
  if(not attacking and not reading and player_turn) draw_combat_menu()
  -- player hp bar
  rectfill(cam_x+12,cam_y+45,cam_x+40,cam_y+40+19,0) -- draw the background.
  rect(cam_x+12,cam_y+45,cam_x+40,cam_y+40+19,7) -- draw the border.
  print("ren\nhp: "..defender.health,cam_x+14,cam_y+47,7)

  --attacker hp bar
  rectfill(cam_x+85,cam_y+45,cam_x+113,cam_y+40+19,0) -- draw the background.
  rect(cam_x+85,cam_y+45,cam_x+113,cam_y+40+19,7) -- draw the border.
  print(fighter.name.."\nhp: "..fighter.health,cam_x+87,cam_y+47,7)
 end
end

function update_combat()
 if(k==31) then k=0 else k+=.5 end
 if(not player_turn) then
 if (talkingto.name=="klanky") then 
   if(attack(talkingto,p)) then enemydmg=flr(rnd(talkingto.attackpower)+1) tb_init(1,{"klanky lunges towards you with \na huge claw arm!","he hit!","you took "..enemydmg.." points of damage!"},cam_x,cam_y+106)
   else tb_init(1,{"klanky lunges towards you with \na huge claw arm!","he missed!"},cam_x,cam_y+106) end
  end
  if (talkingto.name=="cranky") then 
   if(attack(talkingto,p)) then enemydmg=flr(rnd(talkingto.attackpower)+1) tb_init(1,{"cranky fires a huge laser from his arm!","he hit!","you took "..enemydmg.." points of damage!"},cam_x,cam_y+106)
   else tb_init(1,{"cranky fires a huge laser from his arm!","he missed!"},cam_x,cam_y+106) end
  end
  if (talkingto.name=="evilcara") then 
   if(attack(talkingto,p)) then enemydmg=flr(rnd(talkingto.attackpower)+1) tb_init(1,{"cara shoots lasers from her \neyes!","she hit!","you took "..enemydmg.." points of damage!"},cam_x,cam_y+106)
   else tb_init(1,{"cara shoots lasers from her eyes!","she missed!"},cam_x,cam_y+106) end
  end
  player_turn=true
 elseif(not reading and (t>=2.4)) then update_menu()
 elseif(reading) then tb_update()
 end
end

function init_combat(ch)
 player_turn=true
 attacking=false
 playerattacked=false
 precombat=false
 exitcombat=false
 transition=true
 combat=true
 enemydmg=0
 pdmg=0
 k=0
 fighter=deepcopy(ch)
 defender=deepcopy(p)
 defender.flipped=false
 defender.x=cam_x+18
 defender.y=cam_y+64
 fighter.flipped=true
 fighter.x=cam_x+92
 fighter.y=cam_y+64
 sub_mode=2
 init_menu(cam_x+2,cam_y+102,{"attack","reason","action"})
end

function attack(a,b)
 attacking=true
 return flr(rnd(20)+1)>=b.armorclass
end

function reason(a,b)
 attacking=true
 return flr(rnd(20)+1)>=b.reasondc
end

function draw_combat_menu()
 if combat then
  rectfill(tb.x+5,tb.y-20,tb.x+47,tb.y-18+tb.h,tb.col1) -- draw the background.
  rect(tb.x+5,tb.y-20,tb.x+47,tb.y-18+tb.h,tb.col2) -- draw the border.
  draw_combat_options()
 end
end

function draw_combat_options()
 for i=1, m.amt do
  oset=i*6.80
  if i==m.sel then
   rectfill(cx+4,m.y-20+oset-1,cx+38,m.y-20+oset+5,col1)
   print(m.options[i],cx+5,m.y-20+oset,col2)
  else
   print(m.options[i],m.x+5,m.y-20+oset,col1)
  end
 end
end

--Used to make copies of tables without modifying the parent table
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
__gfx__
00666666666666600066666666666660006666666666666000666666666666600066666666666660000000000000000000666666666666600000000000000000
0633bbbbbbbbbbb60633bbbbbbbbbbb60633bbbbbbbbbbb60633bbbbbbbbbbb60633bbbbbbbbbbb600666666666666600633bbbbbbbbbbb60066666666666660
0633baaaaaaaaab60633baaaaaaaaab60633baaaaaaaaab60633baaaaaaaaab60633baaaaaaaaab60633bbbbbbbbbbb60633baaaaaaaaab60633bbbbbbbbbbb6
6223baaacaaacab66223baaaaaaaaab66223baaaaaaaaab66223baaaaaaaaab66223baaacaaacab60633baaaaaaaaab66223baaacaaacab60633baaaaaaaaab6
6223baaacaaacab66223baaacaaacab66223baaaaaaaaab66223baaacaaacab66223baaacaaacab66223baaaaaaaaab66223baaacaaacab66223baaaaaaaaab6
6223baaaaaaaaab66223baaaaaaaaab66223baaaaaaaaab66223baaaaaaaaab66223baaaaaaaaab66223baaacaaacab66223baaaaaaaaab66223baaacaaacab6
0633baaaaaaaaab60633baaaaaaaaab60633baaaaaaaaab60633baaaaaaaaab60633baaaaaaaaab66223baaaaaaaaab60633baaaaaaaaab66223baaaaaaaaab6
0633bbbbbbbbbbb60633bbbbbbbbbbb60633bbbbbbbbbbb60633bbbbbbbbbbb60633bbbbbbbbbbb60633baaaaaaaaab60633bbbbbbbbbbb60633baaaaaaaaab6
006633333333366000663333333336600066333333333660006633333333366000663333333336600633bbbbbbbbbbb600663333333336600633bbbbbbbbbbb6
00006322222360000000632222236000000063222223600000006322222360000000632222236000006633222223366000006322222360000066332222233660
00006322222360000000632222236000000063222223600000006322222360000000632222236000000063222223600007006322222360000000632222236000
00006322222360000000632222236000000063222223600000006322222360007000632222236000700063222223600000006322222360000770632222236000
00006333333360000000633333336000000063333333600000006333333360000000633333336000000063333333600077006333333360000770633333336000
00000636663600000000063666360000000006366636000000000636663600000000063666260000007006366636000077000626663600000000063666360000
00000626062600000000062606260000000006260626000000000626062600000077062607600000000006260626000000000760062600007007062606260000
00000060006000000000006000600000000000600060000000000060006000000770006000000000000000600060000000070000006000000000006000600000
00666666666660000000000000000000006666666666600000000000000000000066666666666000000000000000000000666666666660000000000000000000
06bbbbbbbbbbb600006666666666600006bbbbbbbbbbb600006666666666600006bbbbbbbbbbb600006666666666600006bbbbbbbbbbb6000066666666666000
06baaaaaaaaab60006bbbbbbbbbbb60006baaaaaaaaab60006bbbbbbbbbbb60006bbbbbbbbbbb60006bbbbbbbbbbb60006bbbbbbbbbbb60006bbbbbbbbbbb600
62baacaaacaab26006baaaaaaaaab60062baacaaacaab26006baaaaaaaaab60062bbbbbbbbbbb26006bbbbbbbbbbb60062bbbbbbbbbbb26006bb77bbbbbbb600
62baacaaacaab26062baaaaaaaaab26062baacaaacaab26062baaaaaaaaab26062bbbbbbbbbbb26062bbbbbbbbbbb26062bbbbbbbbbbb26062bb77bbbbbbb260
62baaaaaaaaab26062baacaaacaab26062baaaaaaaaab26062baacaaacaab26062bbbbbbbbbbb26062bbbbbbbbbbb26062bbbbbbbbbbb26062bbbbbbb77bb260
06baaaaaaaaab60062baaaaaaaaab26006baaaaaaaaab60062baaaaaaaaab26006bbbbbbbbbbb60062bbbbbbbbbbb26006bbbbbbbbbbb60062bbbb77b77bb260
06bbbbbbbbbbb60006baaaaaaaaab60006bbbbbbbbbbb60006baaaaaaaaab60006bbbbbbbbbbb60006bb7bbbb7bbb60006bbbbbbbbbbb60006bbbb77bbbbb600
006633333336600006bbbbbbbbbbb600006633333336600006bbbbbbbbbbb600006633333336600006bbbbbbbbbbb600006633377336600006bbbbbbbbbbb600
00063222223600000066322222366000000632222236000000663222223660000006333333360000006633377336600000063337733600000066373337366000
77063222223607700006322222360000000632222236770000063222223600000006377333360000000637377336000000063333333600000006333333360000
77063222223607700006322222360000007632222236770000063222223600000006377333360000000633333336000000063333773600000006333733360000
00063333333600007706333333360000000633333336000077063333333600000006333333360000000677337736000000063333773600000006373333360000
00006266636077007700636663607700077063666260000077006366636077000007726663600000000077667760000000006366626000000000636663600000
07000600626077000007626062607700077062600600700000076260626077000007760062600000000062606260000000006260060000000000626062600000
00070700060000000000060006000000000006000700000000000600060000000000070006000000000006000600000000000600070000000000060006000000
00006677777700000000000000000000000066777777000000000002888000000000000000000000555555555550055500000005555555550055555555000000
00667711111177000000667777770000006677111111770000000028888800000000000288800000555555555550055500000005555555550055555555500000
0667111711711170006677111111770006671117117111700000002818a800000000002888880000555555555550055500000005555555550055555555500000
66711117117111170667111188111170667111171171111700000028888800000000002818a80000000055500000055500000005550005550055000055500000
66711111111111176671111188111117667111111111111700000002888000000000002888880000000055500000055500000005550005550055000005500000
6671117111171117667111118811111766711177777711170000b011100000000000000288800000000055500000055500000005550005550055000005500000
066711177771117066711111111111170667111777711170000b6b88889900000000b01110000000000055500000055500000005550005550055000055500000
0066771111117700066711118811117000667711111177000006b88880099900000b6b8888990000000055500000055500000005550005550055555555500000
00006677777700000066771111117700000066777777000000600110000009000006b88880099900000055500000055500000005550005550055555555500000
00000066666600000000667777770000000000666666000000b08888000c99900060888800000900000055500000055500000005550005550055555555000000
0000006668660070000000666866000000000066686600700b00e00e00c0999000b0e00e000c9990000055500000055500000005550005550055500555000000
0000776688867700000077668886770000007766888677000b00e00e0000c0c00b00e00e00009990000055500000055555555005555555550055500555000000
000700666866000000070066686600700007006668660000060070070000c0c00b0070070000c0c0000055500000055555555005555555550055500055500000
0000006666660000000000666666000000000066666600000600e00e000000006060e00e00000000000055500000055555555005555555550055500055550000
0000011111111000000001111111100000000111111110000000e00e000000000000e00e00000000000000000000000000000000000000000000000000000000
00001111111111000000111111111100000011111111110000007707700000000000770770000000000000000000000000000000000000000000000000000000
00000077777777710000000000000000000999940000000000000000000000000000000000000000000066777777000000000000000000000000000000000000
00000077777777710000000000000000009a991940000000000000000000000000000000000000000066771111117700000bbbb0000022000000000000000000
00000077777777710000000000000000009999994000000000099994000000000000000000000000066711181181117000bbbbbb088020100000000288800000
000000777777777100000000000000000000000600000000009a99194000000000000000000000006671111811811117000bbbb0008020100000002818a80000
000000777777777100000000000000000000ed060de2220000999999400000000000000000000000667111111111111700099994008dd0200000b00288800c00
00000077777777710000000000000000000eeeeeedeed2000000ed060de2220000000000000000006671117777771117009a991940eee020000b6b888899099c
00000077777777710077700000777000000cededeeed0200000eeeeeedeed20000000000000000000667111777711170009999994de2222066b6b88880009990
0000007711111110077777000777770000cc0edeeed00110000cededeeed020000000000000000000066771111117700cccaeeeeedeed200000008880000099c
0000077100000000777777707777777000ca00eeed00002000cc0edeeed00110001ccc00001ccc000000667777770000000bbbb0000000000000000000000000
0000011000000000ccccccc0ccccccc000ac00060000002000ca00eeed000020001aca00001aca00000000666666000000bbbbbb000022000000000288800000
0000000000000000111aaa101aaa111000c000bbbb00010000a000bbbb000020001ccc00001c0c000000006668660070000bbbb0088020000000002818a80000
0000000000000000ccccccc0ccccccc000c00bbbbbb0101000c00bbbbbb001000001c0000001c0000000776688867700000999940080200000000002888000c0
00000000000000006767676067676760006000bbbb00202000c000bbbb0001000011cc000011cc000007006668660000009a9919408dd0010000b01110000c00
00000000000000007676767076767670000000800200000000600080020002000011cc000011cc0000000066666600000099999940eee001060b6b888899099c
0000000000000000cc000cc0cc000cc0000000800200000000000080020000000001c0000001c00000000111111110000000ed060de2220200b6b88880009990
0000000000000000ccc00cccccc00ccc000008802200000000000880220000000001c0000001c0000000111111111100cccaeeeeedeed222060008880000099c
00005d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d2d2d5d5d000000005d2d2d2dce2d2d2d2d2d2d2ddede2d2d5d0000000000000000000000000000
0000000000000000000000000000005d2d2d2d2d5d000000005d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d
00005d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d5d2d2d2d5d2d2d2d5d000000005d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d0000000000000000000000000000
0000000000000000000000000000000f0f0f0f0f0f000000005d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d
00005d2d2d5d5d5d5d5d2d2d5d5d5d5d5d5d5d5d5d2d2d2d5d2d2d2d5d000000005d5d5d5d5d5d5dcdcdcdcd5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d00000000
0000000000000000000000000000001f1f1f1f1f1f000000005d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d
00005d2d2d5d2d2d2d5d2d2d5d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d5d000000005d2d2d2d2d5d5d2d2d2d2d5d5d2d2d2d2d2d2d2d2d2d2d2d2d2d5d00005d5d
5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d2d2d2d2d5d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2e2d5d2d2d5d2d2d2d2d2d2e2d2d2d2d2d5d2e2d2d5d000000005d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d5d00005d2d
2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d5d2d2d2d2d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d2d5d2d2d5d2d2d5d5d5d5d5d5d5d5d5d5d2d2d2e5d000000005d2d2d2d2d2d2d2d2d2d2d2d2e2d2e2d2d2d2d2d2d2d2d2d2d2d5d00005d2d
2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d2d5d2d2d5d2d2e5d2d2d2d2d2d2d2d2d5d2d2d2d5d000000005d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2e2d5d00005d2d
2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2e2d5d2d2d2d5d2d2d5d2d2d5d2d2d2e2d2d2d2d2d5d2d2d2d5d000000005d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d00005d2d
2d2d2d2d2d2e2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2e2d5d5d2d2d5d2d2d5d2d2d2d2d5d5d2d2d5d2d2d2d5d000000005d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d5d00005d2d
2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d5d5d2d2d5d2d2d5d5d5d5d5d5d5d2d2d5d2d2e2d5d000000005d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d00005d2d
2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d2d2d2d2d5d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d5d000000005d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d5d00005d2d
2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d2d2d2d2e5d2d2e2d2d2d2d2d2d2d2d2e5d2d2d2d5d000000005d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2e2d2d2d2d2d2d2d2d5d00005d2d
2d2d2e2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d2d2d2d5d000000005d2d2d2e2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d5d00005d2d
2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2e2d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d5d000000005d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d5d00005d2d
2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2e2d2d2d2d2d2e5d000000005d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d00005d5d
5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444445555555500000000777777776666666655555555555555555555555555555555666666666666666655555555000000000000000000000000
49944449499944495555555500000000777777776666666656666665566600655666000556600005666566666666666666666666000000000000000000000000
9449999494449994555555550000000077777777666666665667666556000005566000055060000566556666666666666666666600000000000d000000000000
444444444444444455555555000000007777777766666666567666655000000556000005500000056555566666666666666666668000000000060000000000b0
44444444444444445555555500000000777777776666666656666665500000655600006550000005665556666666556666666666060000000006000000000600
44444444444999995555555500000000777777776666666656666765560000655000066550000005665566666666566666666666006000000006000000006000
44999944999444445555555500000000777777776666666656666665566606655600666550000065666566666666666666666666000600000006000000060000
99444499444444445555555500000000777777776666666655555555555555555555555555555555666666666666666655555555001110000011100000111000
00000000000000005555555500000000444444446555555555555555555555555555555555555555666666666666666655555555555555555555555511111111
0000000000000000555555350000000044343443666555565cccccc55666cc655666ccc5566cccc5666666566666666655500055505550555055505511ddddd1
0000000000000000555553550000000034333433666665565cc7ccc556ccccc5566cccc55c6cccc5666665566666656655550555550505555055505511daa1d1
0000000000000000535dd3d50000000033333333666665665c7cccc55cccccc556ccccc55cccccc5666665566666566655550555555055555505055511daa1d1
0000000000000000dd3ddddd0000000033333333666666665cccccc55ccccc6556cccc655cccccc5665665666665566655550555550505555505055511daa1d1
0000000000000000dddddd550000000033333333666666665cccc7c556cccc655cccc6655cccccc5665666666666666655550555505550555550555511ddddd1
000000000000000055dddd550000000033333333666666665cccccc55666c66556cc66655ccccc65656666566556666655500055555555555550555511ddddd1
00000000000000005555555500000000333333336666666655555555555555555555555555555555666666666666666655555555555555555555555511ddddd1
000000000000000000000555000000003333333333333333555555553333333333334443556d6d6d1111111111111111546d6d6011111111546d6d6d11111111
00000000000000000550055500000000333333333333333355555555333333333353334455666666111111111111111144666666111111111166666611111111
000000000000000055555555000000003333333333333333555555553333533335333333556d6d6d1111111111111111456d6d6d1111111115606d6111111111
00000000000000005555555500000000333333333333333355aa55aa333533333333353355666666111111111111111155666666111111114566661111111111
000000000000000055555505000000003333333333333333555555553333333333333353556d6d6d1111111111111111556d606d11111111556d6d1111111111
00000000000000005555500000000000343334333333333355555555335333333533333355666666556666661111111155666666444666665566666144461111
000000000000000005555000000000004434344333333333555555553533444333353333556d6d6d556d6d6d11111111546d6d60546d606d546d6061546d6144
00000000000000000055550500000000444444443333333355555555333334443333533355666666556666661111111144666666556666664466666655666664
__label__
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555288855555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555552888885555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555552818a85555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555552888885555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555288855555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555b51115555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
0000000000666666665555555b6b8888995555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555556b88885599955555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555565511555555955555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
000000000066666666555555b58888555c9995555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555b55e55e55c59995555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555b55e55e5555c5c5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
0000000000666666665555565575575555c5c5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555655e55e55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555e55e55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555775775555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555556666666666666555555555555555555555555555555555555555555555555555555555555555
005555555555555555555555555555555555555555555555555633bbbbbbbbbbb655555555555555555555555555555555555555555555555555555555555555
005555555555555555555555555555555555555555555555555633baaaaaaaaab655555555555555555555555555555555555555555555555555555555555555
005555555555555555555555555555555555555555555555556223baaaaaaaaab655555555555555555555555555555555555555555555555555555555555555
005555555555555555555555555555555555555555555555556223baaacaaacab655555555555555555555555555555555555555555555555555555555555555
005555555555555555555555555555555555555555555555556223baaaaaaaaab655555555555555555555555555555555555555555555555555555555555555
005555555555555555555555555555555555555555555555555633baaaaaaaaab655555555555555555555555555555555555555555555555555555555555555
005555555555555555555555555555555555555555555555555633bbbbbbbbbbb655555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555556633333333366555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555563222223655555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555563222223655555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555563222223655555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555563333333655555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555556366636555555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555556265626555555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555555655565555555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000006666666655555555555555555555555555555555555555555555555555555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555555555555555555555555555555555555555555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555555555555555555555555555555555555555555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555555555555555555555555555555555555555555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555555555555555555555555555555555555555555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555555555555555555555555555555555555555555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555555555555555555555555555555555555555555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555555555555555555555555555555555555555555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555556666666666666666666666666666666655555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555556666666666666666666666666666666655555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555556666666666666666666666666666666655555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555556666666666666666666666666666666655555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555556666666666666666666666666666666655555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555556666666666666666666666666666666655555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555556666666666666666666666666666666655555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555556666666666666666666666666666666655555555555555556666666666666666666666666666666666666666666666
00000000006666666655555555555555556666666655555555555555556666666655555555555555556666666655555555555555555555555555555555555555
00000000006666666655555555555555556666666655555555555555556666666655555555555555556666666655555555555555555555555555555555555555
00000000006666666655555555555555556666666655555555555555556666666655555555555555556666666655555555555555555555555555555555555555
00000000006666666655555555555555556666666655555555555555556666666655555555555555556666666655555555555555555555555555555555555555
00000000006666666655555555555555556666666655555555555555556666666655555555555555556666666655555555555555555555555555555555555555
00000000006666666655555555555555556666666655555555555555556666666655555555555555556666666655555555555555555555555555555555555555
00000000006666666655555555555555556666666655555555555555556666666655555555555555556666666655555555555555555555555555555555555555
00000000006666666655555555555555556666666655555555555555556666666655555555555555556666666655555555555555555555555555555555555555

__gff__
0000000000000000000000000404040400000000000000000000000004040404000000000000000000000000040404040000000000000000000000000404040409090909090901010101000000000000090909090909010101010000000000000000010101010101000009090901010100000101010101010101090909010101
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000030001000000000101010100014111000500010000000001010000000181210009000000000001010101010101
__map__
d5d5d5d5e5d5d5d5d5d5e5d5d5d5ebd5d5d5d5d5d5d5e5d5ebd5d5d5d5ebd5d5d5d5e5d5d5d5d5d5e5000000e5dafbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfafbfbfbfbfbfbfbfbfdfbfbfbfbfbfbfbfbfbfbfbfdfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbc0
d5dbd6d6d5d5ebd6d7d5d5d7d9d5d5d5d8d7d5ead5d7d7d5d5ead8d6d5d5d5d9d6d5d5d5d6d9d5d5d5000000eadbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfaf9fbfbfbfafbfbfbfbfbfbfafbf9fbfbfbfbfbfbfbfdfcfffbfbfbfbfbfbfbfbfffbfcfbfbfbfbfbfbfbfbfffbfbfbfffbfbfbfbfbfbfdfbfffbfffbc0
d5d5d8d6d5d5d5d9d8d5d5d9d6d5d5d5d6d9d5d5d5d6d6d5d5d5d6d9dbd5dbd6d6d5d5d5d6d6d5d5d5000000d8eafbfbfbfbfbfbfbfbfbfbfbfbfbfafbfbfbfbfbfbf9f9fbfbfaf9fafbfbfbfbfbfcfaf9fbfbfbfbfbfbfbf9fcfcfafbfbfbfbfbfbfdfefffcfbfdfbfffbfbfbfbfefbfbfbfefbfdfbfbfbfbfcfdfcfbfefdc0
d5d5d6d9d5d5d5d6d6dad5d6d9d5d5d5d6d8dbd5d5d9d7d5ead5d6d6d5ead5d7d8ebd5d5d7d6d5d5eb000000d8dbfbfbfbfbfbfbfbfbfbfbfbfbfaf9fbfbfbfbfbfbf9f9fbfbf9f9f9fbfbfbfbfbf9f9f9fafbfbfbfbfbfbfcfcf9f9fbfbfbfbfbfbfcfefefcfbfefbfefffbfbfbfefbfbfdfcfbfcfbfbfbfbfcfefcfbfefec0
d5d5d5d5dad5ead5d5d5d5d5d5ead5d5d5d5d5ebd5d5d5d5d5d5d5d5d5d5d5d5d5d5d5dad5d5d5d5d5000000d7ebfbfbfbfbfbfbfbfbfbfbfbfbf9f9fbfbfbfbfbfbf9f9fbfbf9f9f9fbfbfbfbfbfcf9fcfcfbfbfbfbfbfbfcfcfcfcfbfbfbfbfbfbfcfcfcfefbfcfbfefcfbfbfbfcfbfbfcfefbfcfbfbfbfbfcfefcfbfefcc0
d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000dbd5e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4c0
d5d2e2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2e2d2d2d5d3d3e3d5eaf5f5f8f5f5f5f5f5f8f5f5f5f5f5f5f5f8f5f5f5f7f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f8f5f5f7f5f5f8f5f5f5f5f5f5f5f8f5f5f5f5f7f5f5f5f5f5f5f8f5f5f5f5f5f5ebc0
d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d3e3d2d2f5f5f5f5f5f5f7f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f8f5f5f5f7f5f5f5f5f5f5f5f5f5f7f5f5f8f5f5f5f5f8f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5eaf3
d5d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d3e3d2d2f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5dbc0
d5d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2e2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d3e3d2d2f5f5f5f7f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f7f5f5f5f5f5f8f5f5f5f7f5f5f8f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f7f5f5f8f5f5f5f5f5f5f5f8f5f5d2d2e0
d5d2e2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d3e3d2d2f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f7f5f5f7f5f5f5f7f5f5f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5d2d2e0
d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d3d3e3d5d5f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f8f5f5f5f5f8f5f5f5f5f5f5f5f5f5d2d2e0
d5d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2e2d2d2e2d2d2d2d2e2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d5000000d5eaf5f7f5f7f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f8f5f5f5f5f5f5f7f5f5f7f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f7f5f5f5f5f5dbc0
d5d2e2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d5000000d5d5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f7f5f7f5f5f5f5f5f5f5f5dac0
d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000d5daf5f5f5f5f5f5f5f7f5f5f5f5d2d2d2f5f5f5f8f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5d2d2d2f5f5f5f5f5f5f8f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f8f8f5f5f5eac0
d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5000000d5d5f4f4f4f4f4f4f4f4dad5dbd5d2d2d2eadbebd5f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4d5d5d5d5d2d2d2d5d5d5d5f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4c0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c0c0c0c0c0c0c0c0c0c0f3f3f3f3f3f3c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0f1f1f1c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d3d3d3d3d3d3d300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5d2d2d2d2d50000000000000000000000000000000000000000d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5
0000d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5000000000000000000000000000000000000000000000000000000000000000000d5d5d2d2d2d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5
0000d5d2d2e2e2d2d2d2d2d2e2d2e2e2d2d2d2d2d2d2d2d2d5d2d2d2d500000000d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5000000000000000000000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5
0000d5d2d2e2e2d2d2e2d2d2e2d2e2e2d2d2d2d2d2d2d2d2d5d2d2e2d500000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000000000000000000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5
0000d5d2d2d2e2d2e2e2e2d2e2d2e2e2d2d2d2d2d2d2d2d2d5d2d2d2d500000000d5d2d2eceed2d2d2e2d2d2d2eed2d2d2d5000000000000000000000000d5d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d5000000d5d2d2d2d2e2e2e2e2d2d2d2d2d2d2e2e2e2e2d2d2d2d2d2d2e2e2e2e2d2d2d2d2d2d2d2d2d2d5
0000d5d2d2d2e2d2d2e2d2d2e2d2e2e2d2d5d5d2d2e2d2d2d5d2d2d2d500000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000000000000000000000d5d2d2d2e2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2e2d2d2d500d3d3d5d2d2d2e2d2d2d2d2e2d2d2d2d2e2d2d2d2d2e2d2d2d2d2e2d2d2d2d2e2d2d2d2d2d2d2d2d2d5
d3d3d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d2d2d2d2d2d5d2d2d2d500000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000000000000000000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d500d3d2d2d2d2e2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d5
d3d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d2d2d5d500000000d5d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d5000000000000000000000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d500d3d2d2d2d2e2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d5
d3d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5e2d2d5d5e1e1f3f3d5d2d2d2d2d2efefefefefd2d2d2d2d2d5000000000000000000000000d5d2d2d2e2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d500d3d2d2d2d2e2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d5
d3d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d2d2e1f3d2d2d2d2d2d2d2ef000000efd2d2e2d2d2d5000000000000000000000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d500d3d2d2d2d2e2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d5
d3d3d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d2d2d2d5d2d2d2d2d2e1f3d2d2d2e2d2d2d2efefefefefd2d2d2d2d2d5000000000000000000000000d5d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d500d3d2d2d2d2e2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d5
0000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d5d2d2d2d5d2d2d2d2d2e1f3d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000000000000000000000d5d2e2d2d2d2d2d2d2d2e2d2d2d2d2d2e2d2d2d2d2d2d2d500d3d3d5d2d2d2e2d2d2d2d2e2d2d2d2d2e2d2d2d2d2e2d2d2d2d2e2d2d2d2d2e2d2d2d2d2d2d2d2d2d5
0000d5d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d5d2d2d2d2d2e1f3d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000000000000000000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000d5d2d2d2d2e2e2e2e2d2d2d2d2d2d2e2e2e2e2d2d2d2d2d2d2e2e2e2e2d2d2d2d2d2d2d2d2d2d5
0000d5d2d2d2d2d2e2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d5d2d2d5d5e1e1f3f3d5d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d5000000000000000000000000d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d2d2d2d2d5d5000000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5
__sfx__
950e00001303513005000050000520005000051f005000051d0050000500005000051d0050000500005000051d0050000500005000051d0050000500005000051d0050000500005000051d00500005000051f005
b104010024725245001c0001c0001c0001c0001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4909010000425003001a3000030400304003040030400304003040030400304003040030400304003040030400304003040030400304003040030400304003040030400304003040030400304003040030000300
650501002352500500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
4d0401001054500503000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
910c080028645326450000526635000001a625000000e615000003260000000326000000032605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9110002026610266112661126611256112561124611226111e611196110f6110761103611016110061100611006110061100611036110861111611186111e6112261124611256112761127611286112861128610
000e01001d03001400014000140001400014000140001400014000140001400014000140001400014000140001400014000140001400014000140001400014000140001400014000140001400014000140001400
490e00200010000100051200512000100001000512000100001000010005120051200010000100051200010000100001000512000100001000010005120051200010000100051200010000100001000512005120
010600000055002551045510555107551095510b5510c551006120061200612006120061200612006120061200612006120061200612006120061200612006120061200612006120061202611046110561100000
010c0000150231502015020150201502015020150201502015020150201502015023280502b050300523005200000000000000000000000000000000000000000000000000000000000000000000000000000000
a70c001000523005230052300503005030052330633005230052300503005030050000523005233063330600005003c5000050000500005003c50000500005000050000500005000000000000000000000000000
0d0c0020100131301309112091130911205013001001710017013170130b1120b1130b1120b1140b0130b11418013180130c1120c1130c1120c01300100171001701317013081120811308112081140801308114
550c00201121313213152111521315211112130c20017200172131721317212172131721217214172131721418213182131821218213182121821318200172001721317213142121421314212142141421314214
180e00002452024520245202452024520245202452024520245202452024520245202452024520245202452029520295202952029520295202952029520295202952029520295202952029520295202952029520
bf1000200c1330d1330c1330d1330c1330d1330c1330d1330c1330d1330c1330d1330c1330d1330c1330d1330c1330d1330c1330d1330c1330d1330c1330d1330c1330d1330c1330d1330c1330d1330c1330d133
4b1000080007300000000733b6003b6553b6000000000073006000060000600006000060000600006000060000600006000060000600006000060000600006000060000000000000000000000000000000000000
cb1000102323123231232312323123231232312323123231002010020100201002010020100201002010020100201002010020100201002010020100201002010020100201002010020100201002000020000200
910e0000200200000000000000001f0200000020020000001802000000000000000018020000000000000000180200000000000000001802000000000001a0201b0200000018020000001b020000001d02000000
052000201502010020150201002015020100201502010020150200e020150200e020150200e020150200e020130200c020130200c020130200c020130200c02012022120220b02012022120220b0201202212022
001000201302016020130201702013020160201702013020160201302017020130201602017020130201102014020110201502011020140201502011020140201102015020110201402015020110201402011020
490e00000000000000001200012000000000000012000000000000000000120001200000000000001200000000000000000012000000000000000000120001200000000000001200000000000000000012000120
a90e00001b0111b0101b0101b0101b0101b0101b0101b0101b0101b0101b0101b0101b0101b0101b0101b01018011180101801018010180101801018010180101801018010180101801018010180101801018010
490e00000000000000011200112000000000000112000000000000000001120011200000000000011200000000000000000112000000000000000001120011200000000000011200000000000000000112001120
a90e00001901119010190101901019010190101901019010190101901019010190101901019010190101901018011180101801018010180101801018010180101801018010180101801018012180121801218012
910e2000200200000000000000001f0200000020020000001802000000000000000018020000000000000000180200000000000000001802000000000001a0201b0200000018020000001b020000001d02000000
490e00000000000000031200312000000000000312000000000000000003120031200000000000031200000000000000000312000000000000000003120031200000000000031200000000000000000312003120
a90e00001b0111b0101b0101b0101b0101b0101b0101b0101b0101b0101b0101b0101b0101b0101b0101b0101f0111f0101f0101f0101f0121f0121f0121f0121f0121f0121f0121f0121f0121f0121f0121f012
910e00002202024020000000000020020000001f020000001d0200000000000000001d0200000000000000001d0200000000000000001d0200000000000000001d0200000000000000001d02000000000001f020
090e00001f7401f74018730187300000000000187401874000000000001674016740000000000014740147400000000000187401874000000000001a7401a74000000000001b7401b740137401d7301d73000000
010c002010503075130751315503155030b5130b513175030b513175031750317503175030b5130b513175030c513185031850318503185030c5130c513175030b5130b513145030851314503185030c51314503
a10c00002471226710297102671024712267102971026710247122671029710267102471226710297102671024712267102971026710247122671029710267102471226710297102671024712247122671426712
a10c0000287101870029712297122971229712287102871026712267122671226712000001f700000001c70028710187002971229712297122971228710287102b7122b7122b7122b71200000000000000000000
a10c000028710187002971229712297122971228710287102d7122d7122d7122d712000001f700000001c70028710187002971229712297122971228710287102f7122f7122f7122f71200000000000000000000
a10c00002b71218702297122971229712297122b7122b7122d7122b712297122b712297122871229712287122671228712267122471226712247122371224712237122171223712217121f712217121f7121d712
a10c00001c7121a7001a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a7121a715
000e00000502405020050200502005020050200502005020050200502005020050200502005020050200002005024050200502005020050200502005020050200502005020050200502005020050200502000020
090e00001f7401f74018730187300000000000187401874000000000001674016740000000000014730147300000000000187401874000000000001a7401a74000000000001b7401b740137301d7401d74000000
000e00000502405020050200502005020050200502005020050200502005020050200502005020050200002005024050200502005020050200502005020050200502005020050200002007024070200702000020
090e00001f7401f74018740187400000000000187301873000000000001674016740000000000013740137400c7400c740187401874000000000001a7301a73000000000001b7401b7400f7401a7301a73000000
000e00000002400020000200002000020000200002000020000200002000020000200002000020000200002000024000200002000020000200002000020000200002000020000200002000020000200002000020
090e00001f7401f74018740187400000000000187301873000000000001674016740000000000013740137400c7300c730187401874000000000001a7401a74000000000001b7301b730000001a7401a74000000
000e00000002400020000200002000020000200002000020000200002000020000200002000020000200002000024000200002000020000200002000020000200002000020000200002003024030200302000020
090e00001f7401f74018730187300000000000187401874000000000001674016740000000000014740147401173011730187401874000000000001a7401a74000000000001b7401b740137401d7301d73000000
390e00001b5201b5201b5201b5201b5201b5201b5201b5201b5101b5101b5101b5101b5101b5101b5101b5101f5201f5201f5201f5201f5201f5201f5201f5201f5101f5101f5101f5101f5101f5101f5101f510
090e00001f7401f74018730187300000000000187401874000000000001674016740000000000014730147301174011740187401874000000000001a7401a74000000000001b7401b740137301d7401d74000000
390e00001b5201b5201b5201b5201b5201b5201b5201b5201b5101b5101b5101b5101b5101b5101b5101b5101a5201a5201a5201a5201a5101a5101a5101a5101d5201d5201d5201d5201d5101d5101d5101d510
390e00001852018520185201852018520185201852018520185101851018510185101851018510185101851016520165201652016520165201652016520165201651016510165101651016510165101651016510
090e00001f7501f75018750187500000000000187501875000000000001674016740000000000013740137400c7400c740187301873000000000001a7301a73000000000001b7201b7200f7200f7201a7201a720
000e20000002400020000200002000020000200002000020000200002000020000200002000020000200002000024000200002000020000200002000020000200002000020000200000003024030200302001400
390e00001852018520185201852018520185201852018520185101851018510185101851018510185101851016520165201652016520165101651016510165101352013520135201352013510135101351013510
010e00000c043000003e215000000c6353e2143e215000000c043000003e215000000c635000003e215000000c043000003e215000000c6353e2143e2153e2140c043000003e215000000c635000003e21500000
490e00000000000000131641316000000000001316413160000000000013164131600000000000131641316000000000001316413160000000000013164131600000000000131641316000000000001316413160
080e000022742000000000022742000000000022742000000000000000227420000022742000001f7420000026742000000000026742000000000026742000000000000000267420000026742000002474200000
080e00001f74000000000001f74000000000001f7400000000000000001f740000001f74000000000000000022740000000000022740000000000022740000000000000000227400000022740000000000000000
010e00000c0430000000000000000c6350000000000000000c0530000000000000000c6350000000000000000c0530000000000000000c6350000000000000000c0530000000000000000c635000000000000000
490e00000000000000111641116000000000001116411160000000000011164111600000000000111641116000000000001116411160000000000011164111600000000000111641116000000000001116411160
080e000021742000000000021742000000000021742000000000000000217420000021742000001d7420000024742000000000024742000000000024742000000000000000247420000024742000002674200000
080e00001d74000000000001d74000000000001d7400000000000000001d740000001d74000000000000000021740000000000021740000000000021740000000000000000217400000021740000000000000000
490e000000000000000f1640f16000000000000f1640f16000000000000f1640f16000000000000f1640f16000000000000f1640f16000000000000f1640f16000000000000f1640f16000000000000f1640f160
490e000000000000000e1640e16000000000000e1640e16000000000000e1640e16000000000000e1640e16000000000000e1640e16000000000000e1640e16000000000000e1640e16000000000000e1640e160
080e1f0021742000000000021742000000000021742000000000000000217420000021742000001d7420000024742000000000024742000000000024742000000000000000247420000024742000002674201400
090e1d001d74000000000001d74000000000001d7400000000000000001d740000001d74000000000000000021740000000000021740000000000021740000000000000000217400000021740014000140001400
010e00000c0430000000000000000c6350000000000000000c0430000000000000000c6350000000000000000c0430000000000000000c6350000000000000000c0430000000000000000c635000000c6350c625
__music__
03 06505144
00 094e4b44
00 0b4e4b44
01 0b0c0d4c
00 0b0c0d4c
00 0b0d4a0c
00 0b0d4a0c
00 5e0b1f0c
00 0b5e200c
00 0b0c2021
00 0b0c2261
00 0b0c2361
02 0b0c4a4c
00 4b4d4a4c
01 4f501144
03 0f101144
01 1d244240
00 25264440
00 27284640
00 292a4840
00 2b242c40
00 2d262e40
00 27282f40
00 30313240
00 2b242c33
00 2d262e33
00 27282f33
00 30313233
00 2b242c33
00 2d262e33
00 27282f33
02 30313233
00 48424344
00 08424344
01 1c47084e
00 12401556
00 1c401758
00 19401a5b
00 1c470816
00 12401518
00 1c40171b
02 19401a18
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 34353637
00 38393a37
00 3b353637
02 3c3d3e3f

