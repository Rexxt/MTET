local Object = require "classic"

local ParticleSystem = Object:extend()
function ParticleSystem:new(image)
    if not type(image) == "userdata" then
        error("particle system: expected image, got "..type(image), 2)
    end
    self.image = image
    self.particles = {}
    self.particle_speed = 50
    self.particle_size = 1
    self.particle_rotation_range = {0, 2*math.pi}
    self.particle_expiration = 1
    self.particle_init = function(part) end
    self.particle_update = function(part, dt)
        part.x = part.x + part.speed*part.mod_x*dt
        part.y = part.y + part.speed*part.mod_y*dt
        part.size = 1 - part.life/part.expiration
    end
end

function ParticleSystem:setParticleRotationRange(min, max)
    self.particle_rotation_range = {min or 0, max or 2*math.pi}
    return self.particle_rotation_range
end

function ParticleSystem:spawnParticle(x, y)
    local px = x or 0
    local py = y or 0
    local rotation = self.particle_rotation_range[1] + love.math.random() * (self.particle_rotation_range[2] - self.particle_rotation_range[1])
    local particle = {
        x = px,
        y = py,
        image = image or self.image,
        mod_x = math.cos(rotation),
        mod_y = math.sin(rotation),
        speed = self.particle_speed,
        life = 0,
        expiration = self.particle_expiration,
        size = self.particle_size,
        color = {1, 1, 1, 1},
        update = self.particle_update
    }
    self.particle_init(particle)
    table.insert(self.particles, particle)
    return particle
end

function ParticleSystem:update(dt)
    if not type(dt) == "number" or dt == nil then
        error("particle system: expected numeric dt, got "..type(dt))
    end
    local i = 1
    while i <= #self.particles do
        local v = self.particles[i]
        v.life = v.life + dt
        v:update(dt)
        if v.life >= v.expiration then
            table.remove(self.particles, i)
        else
            i = i + 1
        end
    end
end

function ParticleSystem:draw(ox, oy)
    for i, v in ipairs(self.particles) do
        local x = v.x - self.image:getWidth()/2 * v.size
        local y = v.y - self.image:getHeight()/2 * v.size
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(v.color[1], v.color[2], v.color[3], v.color[4])
        love.graphics.draw(v.image, x + ox, y + oy, 0, v.size, v.size)
        love.graphics.setColor(r, g, b, a)
    end
end

return ParticleSystem