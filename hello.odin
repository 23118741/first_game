#+feature dynamic-literals
package game

import rl "vendor:raylib"

Animation_Name :: enum {
	Idle, 
	Run,
}

Animation :: struct{
	texture: rl.Texture2D,
	num_frames: int,
	frame_timer: f32,
	current_frame: int,
	frame_length: f32,
	name: Animation_Name, 
}
update_animation :: proc(a: ^Animation){
	a.frame_timer += rl.GetFrameTime()

	for a.frame_timer > a.frame_length{
		a.current_frame += 1
		a.frame_timer -= a.frame_length

		if a.current_frame == a.num_frames {
			a.current_frame = 0
		}
	}
}

draw_animation :: proc(a: Animation, pos: rl.Vector2, flip: bool){
	width := f32(a.texture.width)
	height := f32(a.texture.height)

	source_width := f32(width / f32(a.num_frames))

	source := rl.Rectangle{
		x = f32(a.current_frame) * source_width,
		y = 0,
		width = source_width,
		height = height
	}

	if flip{
		source.width = -source.width
	}

	dest := rl.Rectangle {
		x = pos.x,
		y = pos.y,
		width = width / f32(a.num_frames),
		height = height,
	}
	
	rl.DrawTexturePro(a.texture,source, dest, {dest.width/2, dest.height}, 0, rl.WHITE)	
	
}

PixelWindowHeight :: 180

Level :: struct {
	platforms: [dynamic]rl.Vector2,
}

platform_collider :: proc(pos: rl.Vector2) -> rl.Rectangle {
	return {
		pos.x, pos.y,
		96, 16
	}
}

main :: proc() {
	rl.InitWindow(1280,720, "first game")
	rl.SetWindowPosition(200, 200)
	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(500)
	player_pos: rl.Vector2
	player_vel: rl.Vector2
	player_grounded: bool
	player_flip: bool

	player_run := Animation{
		texture = rl.LoadTexture("cat_run.png"),
		num_frames = 4,
		frame_length = 0.1,
		name = .Run,
	}

	player_idle := Animation {
		texture = rl.LoadTexture("cat_idle.png"),
		num_frames = 2,
		frame_length = 0.5,
		name = .Idle, 
	}

	current_anim := player_run


	level := Level {
		platforms = {
			{-20, 20},
			{90, -10},
			{90, -50},
		},
	}
	
	platform_texture := rl.LoadTexture("platform.png")
	editing := false

	for !rl.WindowShouldClose(){
		rl.BeginDrawing()
		rl.ClearBackground(rl.DARKGREEN)
		rl.DrawFPS(10, 10)

		if rl.IsKeyDown(.LEFT){
			player_vel.x = -100
			player_flip = true
			if current_anim.name != .Run {
				current_anim = player_run
			}
		} else if rl.IsKeyDown(.RIGHT){
			player_vel.x = +100
			player_flip = false
			if current_anim.name != .Run{
				current_anim = player_run
			}
		}else {
			player_vel.x = 0
			if current_anim.name != .Idle{
				current_anim = player_idle
			}
		}

		player_vel.y += 2000*rl.GetFrameTime()
		
		player_pos += player_vel*rl.GetFrameTime()

		player_feet_collider := rl.Rectangle {
			player_pos.x -4,
			player_pos.y -4,
			8,
			4,
		}

		player_grounded = false
		for platform in level.platforms{
			if rl.CheckCollisionRecs(player_feet_collider, platform_collider(platform)) && player_vel.y > 0{
				player_vel.y = 0
				player_pos.y = platform.y
				player_grounded = true
			}	
		}

		if player_grounded && rl.IsKeyDown(.SPACE){
			player_vel.y = -400
		}

		update_animation(&current_anim)

		screen_height := f32(rl.GetScreenHeight())

		camera := rl.Camera2D {
			zoom = screen_height/PixelWindowHeight,
			offset = {f32(rl.GetScreenWidth()/2), screen_height/2},
			target = player_pos,
		}

		rl.BeginMode2D(camera)
		draw_animation(current_anim, player_pos, player_flip)
		for platform in level.platforms{
			rl.DrawTextureV(platform_texture, platform, rl.WHITE)
		}
		//rl.DrawRectangleRec(player_feet_collider, {0, 255, 0, 100})

		if rl.IsKeyPressed(.F2){
			editing = !editing
		}

		if editing {
			mp := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

			rl.DrawTextureV(platform_texture, mp, rl.WHITE)
		}
		
		rl.EndMode2D()
		rl.EndDrawing()
	}
}
