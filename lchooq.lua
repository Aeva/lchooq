
-- Copyright 2023 Aeva Palecek
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

set_title("L. C. H. O. O. Q.")
hide_debug_menu()

set_fixed_camera(
	0, -13, -1,
	0, 0, -1,
	0, 0, 1)

color = css_color("tangerine")
steps = 128

blob_material = solid_material(color)
step_materials = {}

local wheel_model = nil
local segment = sphere(1):move_z(2)

for i=1, steps, 1 do
	local step_material = solid_material(color)
	table.insert(step_materials, step_material)

	local angle = (360 / steps * (i-1)) + 180
	local swatch = segment:rotate_y(angle):paint(step_material)
	wheel_model = wheel_model and wheel_model:union(swatch) or swatch
end

local swatch_model = sphere(1.75)
	:move_z(-3.6)
	:paint(blob_material)

push_meshing_density(40)
wheel = wheel_model:instance()
swatch = swatch_model:instance()


function as_angle(scalar, range)
	return (scalar / range) * 360
end

function as_scalar(angle, range)
	local angle = math.fmod(angle, 360)
	if (angle < 0) then
		angle = angle + 360
	end
	return (angle / 360) * range
end

function lightness_shift(new_shift)
	function shift(param, offset)
		return as_scalar(as_angle(param, 1) + offset, 1)
	end

	color = oklch_color(color)
	color = oklch_color(shift(color.l, new_shift), color.c, color.h)

	set_bg(oklch_color(shift(color.l, 180), color.c, color.h))
	blob_material:set_color(color)

	for i=1, steps, 1 do
		local angle = (360 / steps * (i-1))
		step_materials[i]:set_color(oklch_color(shift(color.l, angle), color.c, color.h))
	end
end

function chroma_shift(new_shift)
	function shift(param, offset)
		return as_scalar(as_angle(param, .5) + offset, .5)
	end

	color = oklch_color(color)
	color = oklch_color(color.l, shift(color.c, new_shift), color.h)

	set_bg(oklch_color(color.l, shift(color.c, 180), color.h))
	blob_material:set_color(color)

	for i=1, steps, 1 do
		local angle = (360 / steps * (i-1))
		step_materials[i]:set_color(oklch_color(color.l, shift(color.c, angle), color.h))
	end
end

function hue_shift(new_shift)
	color = oklch_color(color)
	color = oklch_color(color.l, color.c, color.h + new_shift)

	set_bg(oklch_color(color.l, color.c, color.h + 180))
	blob_material:set_color(color)

	for i=1, steps, 1 do
		local angle = (360 / steps * (i-1))
		step_materials[i]:set_color(oklch_color(color.l, color.c, color.h + angle))
	end
end

shifters = {
	lightness_shift,
	chroma_shift,
	hue_shift
}
current_shifter = #shifters

function repaint(new_shift)
	shifters[current_shifter](new_shift)
end


repaint(0)

wheel:on_mouse_down(function (event)
	local x = event.cursor.x
	local z = event.cursor.z
	local angle = (math.deg(math.atan(event.cursor.x, event.cursor.z)) + 180) or 0
	print(angle)
	repaint(angle)
end)

swatch:on_mouse_down(function (event)
	current_shifter = (current_shifter % #shifters) + 1
	repaint(0)
end)

