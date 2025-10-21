package main

import "core:fmt"
import "core:mem"
import "core:math/rand"

import rl "vendor:raylib"

Width :: 1720
Height :: 1240

dist_btw_lines :: proc(vcount: int, hcount: int) -> f32{
	vsize :=  f32(Width) / f32(vcount + 1)
	hsize := f32(Height) / f32(hcount + 1)
	return min(vsize, hsize)
}

get_hpos_for_hlines :: proc(hlines: [dynamic]f32, i: int) -> int{
	even_num_correct := 1
	if len(hlines) % 2 == 0 {
		even_num_correct = -1
	}else{
		even_num_correct = 1
	}
	return (ceil(f32(len(hlines))/2) + sign_of_neg_one(i) * even_num_correct * ceil(f32(i) / 2)) - 1
}

// ------ utils section ----------
ceil :: proc(num: f32) -> int{
	if f32(int(num)) == num{
		return int(num)
	}
	else{
		return int(num) + 1
	}
}

sign_of_neg_one :: proc(i: int) -> int{
	if i % 2 == 0{
		return 1
	}
	else{
		return -1
	}
}

Grid :: struct{
	columns: [dynamic]Column,
}

Column :: struct{
	hpos: [dynamic]f32,
	vpos: f32
}

generate_points_for_column :: proc(num_of_columns: int, given_column: int, amount_of_points: int, allocator := context.allocator) -> Column{
	hpos := make([dynamic]f32, allocator)
	vpos := f32(given_column + 1) * f32(Width) / f32(num_of_columns + 1)

	for i in 0..<amount_of_points{
		append(&hpos, f32(i + 1) * f32(Height)/f32(amount_of_points + 1))
	}

	return Column{hpos = hpos, vpos = vpos} 
}

main :: proc() {
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, context.allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)

	rl.InitWindow(1720, 1240, "my window")
	rl.SetTargetFPS(60)

	//size: f32 = 50.0
	min_space: f32 = 50.0
	//offset: f32 = 70.0

	vlines: [dynamic]f32
	vcount := 6
	for i in 0..<vcount{
		append(&vlines, f32(i + 1) * f32(Width)/f32(vcount + 1))
	}

	hlines: [dynamic]f32
	hcount := 5
	for i in 0..<hcount{
		append(&hlines, f32(i + 1) * f32(Height)/f32(hcount + 1))
	}

	rects: [dynamic]rl.Rectangle
	//append(&rects, )

	num_of_columns := 5
	num_of_points := 3
	index := 0

	grid: Grid
	for i in 0..<num_of_columns{
		append(&grid.columns, generate_points_for_column(num_of_columns, i, i + 1))
	}

	for !rl.WindowShouldClose(){
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)

		for column in grid.columns{
			for point in column.hpos{
				rl.DrawCircleV({column.vpos, point}, 10.0, rl.BLUE)
			}
		}

		/*
		if rl.IsKeyPressed(.L){
			vcount += 1
			clear(&vlines)
			min_space *= 0.95 

			for i in 0..<vcount{
				append(&vlines, f32(i + 1) * f32(Width)/f32(vcount + 1))
			}

		}

		if rl.IsKeyPressed(.J){
			vcount -= 1
			clear(&vlines)
			min_space *= 1.05 
			
			for i in 0..<vcount{
				append(&vlines, f32(i + 1) * f32(Width)/f32(vcount + 1))
			}

		}

		if rl.IsKeyPressed(.I){
			hcount += 1
			clear(&hlines)
			min_space *= 0.95 

			for i in 0..<hcount{
				append(&hlines, f32(i + 1) * f32(Height)/f32(hcount + 1))
			}
		}

		if rl.IsKeyPressed(.K){
			hcount -= 1
			clear(&hlines)
			min_space *= 1.05 

			for i in 0..<hcount{
				append(&hlines, f32(i + 1) * f32(Height)/f32(hcount + 1))
			}
		}
		*/

		/*
		for vpos in vlines{
			for ypos, i in hlines{

				
				//rl.DrawLineV({vpos, 0.0}, {vpos, Height}, rl.BLACK)
				//rl.DrawLineV({0.0, ypos}, {Width, ypos}, rl.BLACK)
				rl.DrawCircleV({vpos, ypos}, 5.0, rl.LIME)

				size := dist_btw_lines(vcount, hcount) - min_space
				hpos := get_hpos_for_hlines(hlines, i)
				//rl.DrawRectangleRec({vpos - size/2, hlines[hpos] - size/2, size, size}, rl.RED)
			}
		}
		*/

		rl.EndDrawing()
	}
	rl.CloseWindow()

	for key, value in tracking_allocator.allocation_map {
		fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
	}
}

