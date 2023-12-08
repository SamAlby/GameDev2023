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
 palbrite(brightness)
 if intro then intro_draw()
 elseif reading then 
  cls()
  draw_menu()
  if(main_menu) then 
   spr(74,40,30,6,2) 
   draw_particles() 
  end
  tb_draw()
 elseif dialogue then 
  p.animate("idle")
  draw_game()
  draw_dia_menu()
 elseif main_menu then  
  draw_menu() 
  spr(74,40,30,6,2)
  draw_particles()
 else draw_game() 
 end
end

function _update60()
 if fading then updatefade()
 elseif intro then intro_update()
 elseif reading then tb_update()
 elseif main_menu or dialogue then update_menu()
 else update_game()
 end
end

function _init()
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
 init_menu(0,50,{"start","controls","exit"})
end

-->8
--menu
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
   print(m.options[i],cx+2,m.y+oset,col2)
  else
   print(m.options[i],m.x+2,m.y+oset,col1)
  end
 end
end

function draw_dia_options()
 p.draw()
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
    if(talkingto.name == "klanky") then talkingto.update_choice(talkingto,m.options[m.sel])
    elseif(talkingto.stages[m.sel]<count(talkingto.options[m.sel])) then talkingto.stages[m.sel]+=1
    end
   end
  end
 end
 col1=pals[palnum][1]
 col2=pals[palnum][2]
 menu_timer+=1
end


function draw_menu()
 cls(col2)
 draw_options()
 draw_particles()
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
 p.update() -- anims & movement
 update_npcs()
 end

function draw_game()
 cls()
 camera_update()
 map(0,0,0,0,128,32)
 p.draw()
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
    q.x += q.spd/2.5
    q.y += sin(q.off)/1.5
    q.off+= min(0.05,q.spd/32)/7
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
  for i=0,32 do
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
 speed=.75,
 anim_time=0,
 anim_wait=0.30,
 stage=0, --numerical sprite modifier
 flipped=true,
 hitbox={x=0,y=0,w=15,h=15},
 state="idle", --string describing animation
 draw=function(self)
  if(reading) p.state="idle"
  p.animate(p.state)
  if(p.flipped)
  then
   spr(p.state,p.x,p.y,2,2,true,false)
  else
   spr(p.state,p.x,p.y,2,2,false,false)
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
   if (hitx(1,p.x+p.dx,p.y,p.w,p.h) or hity(1,p.x+p.dx,p.y,p.w,p.h)) switch_stage(stages.outside)
   if (hitx(2,p.x+p.dx,p.y,p.w,p.h) or hity(2,p.x+p.dx,p.y,p.w,p.h)) switch_stage(stages.mechmedics)
   if (colliding or hitx(0,p.x+p.dx,p.y,p.w,p.h) or hity(0,p.x+p.dx,p.y,p.w,p.h)) p.dx=0
  end
  if (p.dy!=0) then
   if (hity(1,p.x,p.y+p.dy,p.w,p.h)) switch_stage(stages.outside)
   if (colliding or hity(0,p.x,p.y+p.dy,p.w,p.h) or hitx(0,p.x,p.y+p.dy,p.w,p.h)) p.dy=0
  end
  p.x+=p.dx
  p.y+=p.dy
 end,
 animate=function(state)
  if(time()-p.anim_time>p.anim_wait)
  then 
   p.stage+=2
   p.anim_time=time()
   if p.stage>6
   then 
   p.stage=0
   end
  end
  if state=="idle"
  then p.state=0+p.stage 
  elseif state=="runside"
  then p.state=8+p.stage
  elseif state=="runup"
  then p.state=40+p.stage
  elseif state=="rundown"
  then p.state=32+p.stage
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
    {"who are you?","carebot?","how do you pronounce cara?"},
    {"where am i?","mechmedics?","spring city?","used to be?"},
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
   end,
   speak=function(dial)
   	tb_init(1,{dial},cam_x,cam_y+106)
   end
  }

  klanky={
   name="klanky",
   talked=false,
   x=372,
   y=20,
   dx=0,
   dy=0,
   w=16,
   h=16,
   anim_wait=0.4,
   anim_time=0,
   state=70,
   stage=0,
   voice=2,
   flipped=false,
   options={
    {"parts?"," "},
    {"why do you look like that?"," "},
    {"*attack him*"," "}
   },
   stages={1,1,1},
   draw=function(self)
    spr(self.state,self.x,self.y,2,2,self.flipped,false)
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
   update=function(self)
    if nearactor(p,self) then
     if (btnp(4)) then
      handle_dialogue("klanky")
     end
    end
   end,
   animate=function(self)
    if(p.x <= self.x) then self.flipped=true
    else self.flipped=false end
    if (time()-self.anim_time>self.anim_wait)
    then 
     self.stage+=2
     self.anim_time=time()
    if (self.stage>2) self.stage=0
    end
    self.state=70+self.stage
   end,
   speak=function(dial)
   	tb_init(2,{dial},cam_x,cam_y+106)
   end,
   update_choice=function(self,ch)
    if(ch=="chrono-encryption unit?") dialogue=false
    if(ch=="*attack him*") dialogue = false
    if(ch=="i'm sure") dialogue=false
    if(ch=="*step back*") dialogue=false
    if(ch=="not from a murderer!") dialogue = false
    if(ch=="parts?") self.options={{"i'd like to place an order!"," "},{"i'm not interested"," "}}
    if(ch=="why do you look like that?") self.options={{"parts?"," "},{"not from a murderer!"," "},{"who do you take from?"," "}}
    if(ch=="i'm not interested") self.options={{"chrono-encryption unit?"," "},{"i'm sure"," "}}
    if(ch=="quantum data matrix?") self.options={{"chrono-encryption unit?"," "},{"i'm not interested"," "}}
    if(ch=="who do you take from?") self.options={{"i'd like to place an order!"," "},{"mostly?"," "},{"*step back*"," "}}
    if(ch=="i'd like to place an order!") self.options={{"chrono-encryption unit?"," "},{"quantum data matrix?"," "}}
    if(ch=="mostly?") self.options={{"i'd like to place an order!"," "},{"i'm not interested"," "}}
   end
  }
end

function update_npcs()
 cara:update(cara)
 klanky:update(klanky)
end

function draw_npcs()
 cara:draw(cara)
 klanky:draw(klanky)
end

function npcs_colliding()
 local colliding
 if (hitactor(p,cara)) colliding=true
 if (hitactor(p,klanky)) colliding=true
 return colliding
end

function handle_dialogue(c)
  local q = nil
  dialogue=true
  sub_mode=1
  if(c=="cara")then
   q = cara
   if(q.talked) then tb_init(1,{"i'm sure you'll find what \nyou're looking for!"},cam_x,cam_y+106)
   else tb_init(1,{"hey you! you're finally\npowered on! i was getting\nworried, you know."},cam_x,cam_y+106) end
  end
  if c=="klanky" then
   q = klanky
   if (q.talked) then tb_init(2,{"go on. scram, kid."},cam_x,cam_y+106)
   else tb_init(2,{"hey kid, wanna buy some parts?"},cam_x,cam_y+106) end
  end
  talkingto=q
  if(talkingto.talked) then dialogue=false
  else init_menu(cam_x+2,cam_y+102,{q.options[1][q.stages[1]],q.options[2][q.stages[2]],q.options[3][q.stages[3]]}) end
end

function handle_response(sel)
  if(sel=="who are you?") return {"my name is cara.\ni am a carebot.\ni am here to help!"}
  if(sel=="where am i?") return {"you are in a mechmedics repair \nfacility, located in spring \ncity. you are safe."}
  if(sel=="how long was i out?") return {"well, i'm not sure how long you \nwere out there before we found \nyou, but you've been here for...","...almost 92 hours."} 
  if(sel=="carebot?") return {"that's right! my function is to \nrepair damaged inorganic units.","just like you!"} 
  if(sel=="mechmedics?") return {"yes... a repair facility for \nrobots.","we send daily patrols \nthroughout spring city \nto recover units in need."} 
  if(sel=="i can't remember anything!") return {"oh no...","i was afraid of this. \nwhile i was repairing you,","i noticed that your memory \ndrive has had some critically \ndamaged components."} 
  if(sel=="how do you pronounce cara?") return {"oh! car-a. like a car, because \ni'm a robot, you know?","care-a would be pretty on the \nnose. thanks for asking!","       **improve favor**"} 
  if(sel=="spring city?") return {"that's right!","spring city was established in \n2094 in what used to be \nthe american southwest.","it started as a small \ncollective of service droids.","together, they pooled \ntheir collective processing\npower to create a settlement."} 
  if(sel=="can you fix it?") return {"unfortunately, i don't have the \nrequired parts here with me.","resources are scarce."} 
  if(sel=="used to be?") return {'yeah!','of course, it was only \nconsidered "america" while \nthere were still humans.',"they've been gone for...","gosh...","decades now."} 
  if(sel=="where can i find the parts?") return {"well,","you'll need a new \nchrono-encryption unit \nand a quantum data matrix.","parts like those are hard \nto come by nowadays.","you'll need to venture to \nthe voltoria hub to find \nreplacements.","just go right, \n\nyou can't miss it. :)"}
  if(sel=="parts?") return {"yessir! i've got all sorts! \nbig, small, old, new...","well, maybe not new. \nslightly used at best.","fair warning, \nany complex parts i'll need \nto put an order in for."}
  if(sel=="why do you look like that?") return {"oh, right","i suppose my body has \nbecome a sort of patchwork quilt \nover the years.","as new parts stopped being \nmanufactured, i've had to resort \nto scavenging replacements for","worn out parts from \nother robots. ","interested in some parts?"}
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
 elseif btnp(4) then -- if already on the last message character and button 🅾️/z is pressed:
  if #tb.str>tb.i then -- if the number of strings to display is larger than the current index (this means that there's another message to display next):
   tb.i+=1 -- increase the index, to display the next message on tb.str
   tb.cur=0 -- reset the buffer.
   tb.char=0 -- reset the character position.
  else -- if there are no more messages to display:
   reading=false -- set reading to false. resumes normal gameplay.
  end
 else donetalking=true
 end
end

function tb_draw() -- this function draws the text box.
 if(not main_menu) draw_game()
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
pal(j,v,1)end end end

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
 end
 if brightness==6 then
  fading=false
  fadecoeff*=-1
 end
end
-->8
 --map stages
function init_stages()
 stages={
  mechmedics={
    px=320,
    py=72,
    sx=0,
    mx=208,
    sy=0,
    my=0,
  },
  outside={
    px=352,
    py=68,
    sx=350,
    mx=888,
    sy=0,
    my=0,
  }
 }
 currstage=stages.mechmedics
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
 cls()
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
66711117117111170667111711711170667111171171111700000028888800000000002818a80000000055500000055500000005550005550055000055500000
66711111111111176671111711711117667111111111111700000002888000000000002888880000000055500000055500000005550005550055000005500000
6671117111171117667111111111111766711177777711170000b011100000000000000288800000000055500000055500000005550005550055000005500000
066711177771117066711171111711170667111777711170000b6b88889900000000b01110000000000055500000055500000005550005550055000055500000
0066771111117700066711177771117000667711111177000006b88880099900000b6b8888990000000055500000055500000005550005550055555555500000
00006677777700000066771111117700000066777777000000600110000009000006b88880099900000055500000055500000005550005550055555555500000
00000066666600000000667777770000000000666666000000b08888000c99900060888800000900000055500000055500000005550005550055555555000000
0000006668660070000700666866000000000066686600700b00e00e00c0999000b0e00e000c9990000055500000055500000005550005550055500555000000
0000776688867700000077668886770000007766888677000b00e00e0000c0c00b00e00e00009990000055500000055555555005555555550055500555000000
000700666866000000000066686600700007006668660000060070070000c0c00b0070070000c0c0000055500000055555555005555555550055500055500000
0000006666660000000000666666000000000066666600000600e00e000000006060e00e00000000000055500000055555555005555555550055500055550000
0000011111111000000001111111100000000111111110000000e00e000000000000e00e00000000000000000000000000000000000000000000000000000000
00001111111111000000111111111100000011111111110000007707700000000000770770000000000000000000000000000000000000000000000000000000
00000077777777710000000000000000000999940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077777777710000000000000000009a991940000000000000000000000000000000000000000000000000000000000bbbb0000022000000000000000000
00000077777777710000000000000000009999994000000000099994000000000000000000000000000000000000000000bbbbbb088020100000000288800000
000000777777777100000000000000000000000600000000009a99194000000000000000000000000000000000000000000bbbb0008020100000002818a80000
000000777777777100000000000000000000ed060de2220000999999400000000000000000000000000000000000000000099994008dd0200000b00288800c00
00000077777777710000000000000000000eeeeeedeed2000000ed060de2220000000000000000000000000000000000009a991940eee020000b6b888899099c
00000077777777710077700000777000000cededeeed0200000eeeeeedeed2000000000000000000ccc00cccccc00ccc009999994de2222066b6b88880009990
0000007711111110077777000777770000cc0edeeed00110000cededeeed020000000000000000000cc000cc0cc000cccccaeeeeedeed200000008880000099c
0000077100000000777777707777777000ca00eeed00002000cc0edeeed0011000000000000000000767676707676767000bbbb0000000000000000000000000
0000011000000000ccccccc0ccccccc000ac00060000002000ca00eeed0000200000000000000000067676760676767600bbbbbb000022000000000288800000
0000000000000000111aaa101aaa111000c000bbbb00010000a000bbbb00002000000000000000000ccccccc0ccccccc000bbbb0088020000000002818a80000
0000000000000000ccccccc0ccccccc000c00bbbbbb0101000c00bbbbbb0010000000000000000000111aaa101aaa111000999940080200000000002888000c0
00000000000000006767676067676760006000bbbb00202000c000bbbb00010000000000000000000ccccccc0ccccccc009a9919408dd0010000b01110000c00
0000000000000000767676707676767000000080020000000060008002000200000000000000000007777777077777770099999940eee001060b6b888899099c
0000000000000000cc000cc0cc000cc000000080020000000000008002000000000000000000000000777770007777700000ed060de2220200b6b88880009990
0000000000000000ccc00cccccc00ccc0000088022000000000008802200000000000000000000000007770000077700cccaeeeeedeed222060008880000099c
00005d2d2d5d2d2d5d2d2d5d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d5d2d2d5d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d5d2d2d5d2d2d5d5d5d5d5d5d5d5d5d5d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d5d2d2d5d2d2d5d2d2d2d2d2d2d2d2d5d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d5d2d2d5d2d2d5d2d2d2d2d2d2d2d2d5d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d5d2d2d5d2d2d5d5d5d5d5d5d5d2d2d5d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d5d2d2d5d2d2d5d5d5d5d5d5d5d2d2d5d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d2d2d2d5d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d2d2d2d2d2d5d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001aca00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0011cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0011cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444445555555500000000777777776666666655555555555555555555555555555555666666666666666600000000000000000000000000000000
49944449499944495555555500000000777777776666666656666665566600655666000556600005666566666666666600000000000000000000000000000000
94499994944499945555555500000000777777776666666656676665560000055660000550600005665566666666666600000000000000000000000000000000
44444444444444445555555500000000777777776666666656766665500000055600000550000005655556666666666600000000000000000000000000000000
44444444444444445555555500000000777777776666666656666665500000655600006550000005665556666666556600000000000000000000000000000000
44444444444999995555555500000000777777776666666656666765560000655000066550000005665566666666566600000000000000000000000000000000
44999944999444445555555500000000777777776666666656666665566606655600666550000065666566666666666600000000000000000000000000000000
99444499444444445555555500000000777777776666666655555555555555555555555555555555666666666666666600000000000000000000000000000000
00000000000000005555555500000000444444446555555555555555555555555555555555555555666666666666666600000000000000000000000000000000
0000000000000000555555350000000044343443666555565cccccc55666cc655666ccc5566cccc5666666566666666600000000000000000000000000000000
0000000000000000555553550000000034333433666665565cc7ccc556ccccc5566cccc55c6cccc5666665566666656600000000000000000000000000000000
0000000000000000535dd3d50000000033333333666665665c7cccc55cccccc556ccccc55cccccc5666665566666566600000000000000000000000000000000
0000000000000000dd3ddddd0000000033333333666666665cccccc55ccccc6556cccc655cccccc5665665666665566600000000000000000000000000000000
0000000000000000dddddd550000000033333333666666665cccc7c556cccc655cccc6655cccccc5665666666666666600000000000000000000000000000000
000000000000000055dddd550000000033333333666666665cccccc55666c66556cc66655ccccc65656666566556666600000000000000000000000000000000
00000000000000005555555500000000333333336666666655555555555555555555555555555555666666666666666600000000000000000000000000000000
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
0000000000000000000000000404040400000000000000000000000004040404000000000000000000000000040404040000000000000000000000000404040409090909090901010101000000000000090909090909010101010000000000000000010101010101000001010101010100000101010101010000010100000101
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000030001000000000101000000000000000500010000000001010000000000000001000000000001010101010101
__map__
d5d5d5d5e5d5d5d5d5d5e5d5d5d5ebd5d5d5d5d5d5d5e5d5ebd5d5d5d5ebd5d5d5d5e5d5d5d5d5d5e5000000e5dafbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfafbfbfbfbfbfbfbfbfdfbfbfbfbfbfbfbfbfbfbfbfdfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbf3
d5dbd6d6d5d5ebd6d7d5d5d7d9d5d5d5d8d7d5ead5d7d7d5d5ead8d6d5d5d5d9d6d5d5d5d6d9d5d5d5000000eadbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfbfaf9fbfbfbfafbfbfbfbfbfbfdfbf9fbfbfbfbfbfbfbfdfcfdfbfbfbfbfbfbfbfbfffbfcfbfbfbfbfbfbfbfbfffbfbfbfffbfbfbfbfbfbfffbfdfbfffbf3
d5d5d8d6d5d5d5d9d8d5d5d9d6d5d5d5d6d9d5d5d5d6d6d5d5d5d6d9dbd5dbd6d6d5d5d5d6d6d5d5d5000000d8eafbfbfbfbfbfbfbfbfbfbfbfbfbfafbfbfbfbfbfbf9f9fbfbfaf9fafbfbfbfbfbfcfaf9fbfbfbfbfbfbfbfcfcfcfafbfbfbfbfbfbfdfefffcfbfdfbfffbfbfbfbfefbfbfbfefbfdfbfbfbfbfcfdfcfbfefdf3
d5d5d6d9d5d5d5d6d6dad5d6d9d5d5d5d6d8dbd5d5d9d7d5ead5d6d6d5ead5d7d8ebd5d5d7d6d5d5eb000000d8dbfbfbfbfbfbfbfbfbfbfbfbfbfaf9fbfbfbfbfbfbf9f9fbfbf9f9f9fbfbfbfbfbfcf9f9fdfbfbfbfbfbfbfcfcfcf9fbfbfbfbfbfbfcfefefcfbfefbfefffbfbfbfefbfbfdfefbfcfbfbfbfbfcfefcfbfefef3
d5d5d5d5dad5ead5d5d5d5d5d5ead5d5d5d5d5ebd5d5d5d5d5d5d5d5d5d5d5d5d5d5d5dad5d5d5d5d5000000d7ebfbfbfbfbfbfbfbfbfbfbfbfbf9f9fbfbfbfbfbfbf9f9fbfbf9f9f9fbfbfbfbfbfcf9f9fcfbfbfbfbfbfbfcfcfcf9fbfbfbfbfbfbfcfefefcfbfefbfefefbfbfbfefbfbfcfefbfcfbfbfbfbfcfefcfbfefef3
d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000dbd5e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4e4f3
d5d2e2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2e2d2d2d5d3d3e3d5eaf5f5f8f5f5f5f5f5f8f5f5f5f5f5f5f5f8f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f3
d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2e2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d3e3d2d2f5f5f5f5f5f5f7f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f3
d5d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d3e3d2d2f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f3
d5d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2e2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d3e3d2d2f5f5f5f7f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f3
d5d2e2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d3e3d2d2f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f3
d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d3d3e3d5d5f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f3
d5d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2e2d2d2e2d2d2d2d2e2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d5000000d5eaf5f7f5f7f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f3
d5d2e2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2e2d2d2d2d2d2d2d2d2d2d2d2d5000000d5d5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f3
d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5000000d5daf5f5f5f5f5f5f5f7f5f5f5f5f5f5f5f5f5f5f5f8f5f5f5f5f5f8f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f3
d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5000000d5d5f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f3
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3
0000d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d2d2d2d2d2d5d2d2d2d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e3e3d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d2d2d2d2d2d5d2d2d2d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e3d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e3d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e3d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d5d3d30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e3e3d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d2d2d5d2d2d2d2d2d30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d2d2d5d2d2d2d2d2d30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d2d2d30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d5d2d2d2d5d3d30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d5d2d2d2d2d2d2d2d2d5d5d5d5d5d5d5d5d5d5d2d2d5d2d2d2d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d5d2d2d5d5d5d5d2d2d5d5d5d5d5d5d5d5d5d5d2d2d5d2d2d2d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010e00002270024700000000000020700000001f700000001d7000000000000000001d7000000000000000001d7000000000000000001d7000000000000000001d7000000000000000001d70000000000001f700
b104010024725245001c0001c0001c0001c0001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9109010000425003001a3000030400304003040030400304003040030400304003040030400304003040030400304003040030400304003040030400304003040030400304003040030400304003040030000300
650501002342000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d0401001052500503000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
910c080028645326450000526635000001a625000000e615000003260000000326000000032605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9110002026610266112661126611256112561124611226111e611196110f6110761103611016110061100611006110061100611036110861111611186111e6112261124611256112761127611286112861128610
000e01001d03001400014000140001400014000140001400014000140001400014000140001400014000140001400014000140001400014000140001400014000140001400014000140001400014000140001400
000e00000000000000051600516000000000000516000000000000000005160051600000000000051600000000000000000516000000000000000005160051600000000000051600000000000000000516005160
010c00000055400552005520055200552005520055200552005520055200552005520055200552005520055200552005520055200552005520055200552005520055200552005520055202561045610556107563
9b0c001036600366003662336600005233662336600005233662336600005233662136621366002f6233062529600366003660036600366003c60036600366003c6033c6033c6033c6033c6033c6033c60300003
bf0c00100052300523005230050300503005233c50300523005230050300503005000050000500005000050000500005003c5000050000500005003c500005000050000500005000050000000000000000000000
0d0c0020102131321309212092130921205213002011720017213172130b2120b2130b2120b2140b2130b21418213182130c2120c2130c2120c21300201172001721317213082120821308212082140821308214
0d0c00201021313213152111521315211112130020117200172131721317211172131721117214172131721418213182131821118213182111821300201172001721317213142111421314211142141421314214
180e00002452024520245202452024520245202452024520245202452024520245202452024520245202452029520295202952029520295202952029520295202952029520295202952029520295202952029520
251000200c0530d0530c0530d0530c0530d0530c0530d0530c0530d0530c0530d0530c0530d0530c0530d0530c0530d0530c0530d0530c0530d0530c0530d0530c0530d0530c0530d0530c0530d0530c0530d053
4b1000080007300000000733b6003b6553b6000000000073006000060000600006000060000600006000060000600006000060000600006000060000600006000060000000000000000000000000000000000000
7a1000102317123171231712317123171231712317123171001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101001010010100101000000000000000
000e0000207600000000000000001f7600000020760000001876000000000000000018760000000000000000187600000000000000001876000000000001a7601b7600000018760000001b760000001d76000000
052000201502010020150201002015020100201502010020150200e020150200e020150200e020150200e020130200c020130200c020130200c020130200c02012022120220b02012022120220b0201202212022
001000201302016020130201702013020160201702013020160201302017020130201602017020130201102014020110201502011020140201502011020140201102015020110201402015020110201402011020
000e00000000000000001600016000000000000016000000000000000000160001600000000000001600000000000000000016000000000000000000160001600000000000001600000000000000000016000160
a90e00002751127510275102751027510275102751027510275102751027510275102751027510275102751024511245102451024510245102451024510245102451024510245102451024510245102451024510
000e00000000000000011600116000000000000116000000000000000001160011600000000000011600000000000000000116000000000000000001160011600000000000011600000000000000000116001160
a90e00002551125510255102551025510255102551025510255102551025510255102551025510255102551024511245102451024510245102451024510245102451024510245102451024512245122451224512
010e2000207600000000000000001f7600000020760000001876000000000000000018760000000000000000187600000000000000001876000000000001a7601b7600000018760000001b760000001d76000000
010e00000000000000031600316000000000000316000000000000000003160031600000000000031600000000000000000316000000000000000003160031600000000000031600000000000000000316003160
610e0000275112751027510275102751027510275102751027510275102751027510275102751027510275102b5112b5102b5102b5102b5122b5122b5122b5122b5122b5122b5122b5122b5122b5122b5122b512
010e00002276024760000000000020760000001f760000001d7600000000000000001d7600000000000000001d7600000000000000001d7600000000000000001d7600000000000000001d76000000000001f760
010c00200055400552005520055200552005520055200552005520055200552005520055200552005520055200552005520055200552005520055200552005520055200552005520055202561045610556107563
__music__
03 06505144
00 094e4b44
00 0b0a4c44
01 0b0d0a4c
00 0b0c0a4c
00 0b0d0a0c
01 0b0d0a0c
02 0b424344
01 4f505144
03 4f505144
00 48424344
01 4047484e
00 52405556
00 40405758
01 4f501144
03 0f101144
00 52405558
00 4040575b
02 59405a58
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 08424344
01 1c47084e
00 12401556
00 1c401758
00 19401a5b
00 1c470816
00 12401518
00 1c40171b
02 19401a18

