package main

import "core:fmt"
import "core:mem"
import "core:math/rand"

import rl "vendor:raylib"

Width :: 1720
Height :: 1240

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

	columns := 1
	rows := 0

	grid: Grid
	/*
	for i in 0..<num_of_columns{
		append(&grid.columns, generate_points_for_column(num_of_columns, i, i + 1))
	}
	*/

	for !rl.WindowShouldClose(){
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)

		if rl.IsKeyPressed(.J){
			rows += 1
			clear(&grid.columns)
			
			for i in 0..<columns{
				if i + 1 == columns{
					append(&grid.columns, generate_points_for_column(columns, i, rows))
				}
				else{
					append(&grid.columns, generate_points_for_column(columns, i, i + 1))
				}
			}

			if columns == rows{
				columns += 1
				rows = 0
			}
		}

		for column in grid.columns{
			for point in column.hpos{
				rl.DrawCircleV({column.vpos, point}, 10.0, rl.BLUE)
			}
		}

		rl.EndDrawing()
	}
	rl.CloseWindow()
	
	for column in grid.columns{
		delete(column.hpos)
	}
	delete(grid.columns)

	for key, value in tracking_allocator.allocation_map {
		fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
	}
}

