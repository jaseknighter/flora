-- norns.online sharing code from: https://github.com/schollz/thirtythree/blob/main/lib/cloud.lua

local Cloud={}


function Cloud:debug(s)
  if mode_debug then
    print("cloud: "..s)
  end
end


function Cloud:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  self.enabled=false
  return o
end

function Cloud:init()
  self:debug("initializing cloud")
  local current_time=os.time2()
  if not util.file_exists(_path.code.."norns.online") then
    print("need to download norns.online")
    do return end
  end

  local script_name="flora"
  -- local share=include("norns.online/lib/share")

  -- start uploader with name of your script
  local uploader=share:new{script_name=script_name}
  if uploader==nil then
    print("uploader failed, no username?")
    do return end
  end

  -- add parameters
  params:add_group("COMMUNITY GARDENS",4)

  -- uploader (CHANGE THIS TO FIT WHAT YOU NEED)
  -- select a save
  local names_dir=_path.data.."flora/nursery/"
  params:add_file("share_upload","upload from nursery",names_dir)
  params:set_action("share_upload",function(y)
    -- prevent banging
    local x=y
    -- params:set("share_upload",names_dir,true)
    if #x<=#names_dir or math.abs(os.time2()-current_time)<2 then
      print("returning")
      do return end
    end


    -- choose data name
    -- (here dataname is from the selector)
    local dataname=share.trim_prefix(x,names_dir)

    --[[
    -- find pset associated with this
    local pset_name,ext=dataname:match"([^.]*).(.*)"
    if ext~="json" then
      print("must have json")
      do return end
    end

    local pset_file=snapshot:pset_from_name(pset_name)
    if pset_file==nil then
      print("could not find pset file")
      do return end
    end
    ]]
    
    params:set("share_message","uploading...")
    _menu.redraw()
    print("uploading "..x.." as "..dataname)

    -- upload json
    pathtofile=x
    target=x
    uploader:upload{dataname=dataname,pathtofile=pathtofile,target=target}

    --[[
    -- upload pset
    -- TODO: check whether this is indeed the full path?
    pathtofile=pset_file
    target="/dev/shm/temp.pset"
    uploader:upload{dataname=dataname,pathtofile=pathtofile,target=target}

    -- upload sounds
    sounds=snapshot:list_sounds(x)
    for _,snd_file in ipairs(sounds) do
      if not string.find(snd_file,"code/thirtythree") then
        self:debug("uploading "..snd_file)
        pathtofile=snd_file
        target=snd_file
        uploader:upload{dataname=dataname,pathtofile=pathtofile,target=target}
      end
    end
    ]]
    
    -- goodbye
    params:set("share_message","uploaded.")
  end)

  -- downloader
  download_dir=share.get_virtual_directory(script_name)
  params:add_file("share_download","download to nursery",download_dir)
  params:set_action("share_download",function(y)
    -- prevent banging
    local x=y
    params:set("share_download",download_dir,true)
    if #x<=#download_dir or math.abs(os.time2()-current_time)<2 then
      do return end
    end

    -- download
    print("downloading!")
    params:set("share_message","downloading...")
    _menu.redraw()
    local msg=share.download_from_virtual_directory(x)

    -- move the temporary pset file to any free slot in the psets
    -- local pset_name=snapshot:pset_next()
    -- os.execute("mv /dev/shm/temp.pset "..pset_name)

    params:set("share_message",msg)
  end)
  
  params:add{type='binary',name='refresh directory',id='share_refresh',behavior='momentary',action=function(v)
    print("updating directory")
    params:set("share_message","refreshing directory.")
    _menu.redraw()
    share.make_virtual_directory()
    params:set("share_message","directory updated.")
  end
}
params:add_text('share_message',">","")
self.enabled=true
end

function Cloud:reset()
  if not self.enabled then
    do return end
  end
  params:set("share_upload",_path.data.."flora/backups/",true)
end


return Cloud