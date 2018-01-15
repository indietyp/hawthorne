# view controller

vc_change = (destination='home') ->
  switch
    when 'home'
      console.log "do stuff"
    when 'player'
      console.log "do stuff"
    when 'admin'
      console.log "do stuff"
    when 'player'
      console.log "do stuff"
    when 'server'
      console.log "do stuff"
    when 'ban'
      console.log "do stuff"
    when 'mutegag'
      console.log "do stuff"
    when 'announcements'
      console.log "do stuff"
    when 'chat'
      console.log "do stuff"
    when 'settings'
      console.log "do stuff"
    else
      return false
  return true
