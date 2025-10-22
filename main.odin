package main

import "core:fmt"
import "core:mem"
import "core:math/rand"

import rl "vendor:raylib"

Width :: 1720
Height :: 1240

Grid :: struct{
	//columns: [dynamic]Column,
	root: ^Node,	
}

Node :: struct{
	val: [2]f32,
	left: ^Node,
	right: ^Node,
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

generate_column :: proc(points: ^[dynamic][2]f32, vpos: f32, num_of_points: int){
	for i in 0..<num_of_points{
		append(points, [2]f32{vpos, f32(i + 1) * f32(Height)/f32(num_of_points + 1)})
	}
}

pow :: proc(num: int, power: int) -> int{
	num := num
	start := num
	if power == 0{
		return 1
	}

	for i in 1..<power{
		num *= start
	}
	return num
}

generate_points :: proc(nodes: int, allocator := context.temp_allocator) -> [dynamic][2]f32{
	if nodes <= 0{
		assert(false, "at least one node needed")
	}

	nodes_modifiable := nodes
	points := make([dynamic][2]f32, allocator)
	//1. generate correct columns number and the number of points in each column
	rows: [dynamic]int

	i := 0
	for{
		dec_val := pow(2, i)
		if dec_val > nodes_modifiable{
			if nodes_modifiable != 0{
				append(&rows, nodes_modifiable)
			}
			break
		}

		append(&rows, dec_val)
		nodes_modifiable -= dec_val
		i += 1
	}
	columns := len(rows)

	/*
	for i in 0..<columns{
		if i + 1 == columns{
			append(&grid.columns, generate_points_for_column(columns, i, rows))
		}
		else{
			append(&grid.columns, generate_points_for_column(columns, i, i + 1))
		}
	}
	*/

	for i in 0..<columns{
		vpos := f32(i + 1) * f32(Width) / f32(columns + 1)
		generate_column(&points, vpos, rows[i])
	}

	fmt.println(rows)

	/*
	for i in 1..=nodes{
		/*
		hpos := make([dynamic]f32, allocator)
		vpos := f32(given_column + 1) * f32(Width) / f32(num_of_columns + 1)

		for i in 0..<amount_of_points{
			append(&hpos, f32(i + 1) * f32(Height)/f32(amount_of_points + 1))
		}
		*/
		//vpos := f32(i + 1) * f32(Width) / f32(columns + 1)
		//hpos := f32(Height)/f32(rows[i] + 1)
		column_index: int 
		if i == 1{
			column_index = 0
		}
		else if i == 2 || i == 3{
			column_index = 1
		}
		else if i >= 4 && i <= 7{
			column_index = 2
		}
		else{
			assert(false, "no")
		}

		vpos := f32(Width) / f32(column_index + 2)

		append(&points, [2]f32{vpos, Height / 2})
	}
	for point in points{
		fmt.println(point)
	}
		*/
	delete(rows)

	return points
}

round :: proc(num: f32) -> int{
	num_int := int(num)
	after_decimal := num - f32(num_int)
	if after_decimal >= 0.5{
		return num_int + 1
	}
	else{
		return num_int
	}
}

main :: proc() {
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, context.allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)

	rl.InitWindow(1720, 1240, "my window")
	rl.SetTargetFPS(60)

	nodes := 16 
	points := generate_points(nodes)

	columns := 1
	rows := 0

	//grid: Grid
	//grid.root = new(Node) 
	//grid.root.val = generate_points_for_column(1, 0, 1)
	/*
	for i in 0..<num_of_columns{
		append(&grid.columns, generate_points_for_column(num_of_columns, i, i + 1))
	}
	*/

	for !rl.WindowShouldClose(){
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)

		if rl.IsKeyPressed(.J){
			delete(points)
			nodes += 1
			points = generate_points(nodes)	
		}

		/*
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
		*/

		for point in points{
			rl.DrawCircleV(point, 10.0, rl.BLUE)
		}

		rl.EndDrawing()
	}
	rl.CloseWindow()
	
	/*
	for column in grid.columns{
		delete(column.hpos)
	}
	delete(grid.columns)
	*/

	for key, value in tracking_allocator.allocation_map {
		fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
	}
}

