package main

import "core:fmt"
import "core:mem"
import vmem "core:mem/virtual"
import "core:math/rand"
import "core:strings"

import rl "vendor:raylib"

Width :: 1720
Height :: 1240

//size: f32 = 50

// ------------ utils -------------
get_rect :: proc(v: [2]f32, size := size) -> rl.Rectangle{
	return {v.x, v.y, size, size}
}

mouse_rect_collission :: proc(rect: rl.Rectangle) -> bool{
	pos := rl.GetMousePosition()
	if pos.x > rect.x &&
	   pos.x < rect.x + rect.width &&
	   pos.y > rect.y &&
	   pos.y < rect.y + rect.height {
		return true
	}
	return false
}

//------- queue section -----------
Queue :: struct($T: typeid){
    data: [dynamic]T,
}

queue_push :: proc(queue: ^Queue($T), elem: T){
    append(&queue.data, elem)
}

queue_pop :: proc(queue: ^Queue($T)) -> T{
	if len(queue.data) == 0{
		return {}
	}
	val := queue.data[0]
    ordered_remove(&queue.data, 0)
	return val
}

queue_empty :: proc(queue: ^Queue($T)){
    clear(&queue.data)
}

queue_print :: proc(queue: Queue($T)){
	b := strings.builder_make()
	strings.write_rune(&b, '[')
	for elem, i in queue.data{
		strings.write_int(&b, elem)
		strings.write_string(&b, ", ")
	}
	pop(&b.buf)
	pop(&b.buf)
	strings.write_string(&b, "]\n")
	fmt.println(strings.to_string(b))
	delete(b.buf)
}

//---------- N-ary tree section -----------
Node :: struct{
	val: NodeVal,
	children: [dynamic]^Node,
}

NodeVal :: struct{
	pos: [2]f32,
	color: rl.Color,
	parent: ^Node,
	depth: int,
}

create_root :: proc(alloc := context.allocator) -> ^Node{
	root := new(Node, alloc)	
	root.children = make([dynamic]^Node, alloc)
	root.val.depth = 1
	root.val.color = rl.RED
	return root
}

add_node :: proc(parent: ^Node, alloc := context.allocator){
	child := new(Node, alloc)	
	child.children = make([dynamic]^Node, alloc)
	child.val.depth = parent.val.depth + 1
	//child.val.parent_pos = parent.val.pos
	child.val.parent = parent
	child.val.color = rl.RED
	append(&parent.children, child)
}

get_node_at_idx :: proc(root: ^Node, i: int) -> ^Node{
	queue: Queue(^Node)
	defer delete(queue.data)
	queue_push(&queue, root)

	iter := 0
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		if iter == i{
			return cur_node 
		} 
		iter += 1

		for child in cur_node.children{
			queue_push(&queue, child)
		}
	}
	return {}
}

get_node_count :: proc(root: ^Node) -> int{
	queue: Queue(^Node)
	queue_push(&queue, root)

	iter := 0
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		iter += 1

		for child in cur_node.children{
			queue_push(&queue, child)
		}
	}
	delete(queue.data)
	return iter 
}

print :: proc(root: ^Node){
	queue: Queue(^Node)
	defer delete(queue.data)
	queue_push(&queue, root)

	iter := 0
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		iter += 1
		fmt.println(iter, " ", cur_node.val)

		for child in cur_node.children{
			queue_push(&queue, child)
		}
	}
}

get_height :: proc(root: ^Node) -> int{
	queue: Queue(^Node)
	queue_push(&queue, root)

	max := 0
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		if cur_node.val.depth > max{
			max = cur_node.val.depth
		}

		for child in cur_node.children{
			queue_push(&queue, child)
		}
	}
	delete(queue.data)
	return max 
}

get_rows :: proc(root: ^Node, alloc := context.allocator) -> []int{
	height := get_height(root)
	rows := make([dynamic]int, height, alloc)
	queue: Queue(^Node)
	queue_push(&queue, root)

	max := 0
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		rows[cur_node.val.depth - 1] += 1

		for child in cur_node.children{
			queue_push(&queue, child)
		}
	}
	delete(queue.data)
	return rows[:]
}

generate_node_data :: proc(root: ^Node){
	rows := get_rows(root)
	defer delete(rows)

	height := get_height(root) 

	iter: int
	for i in 0..<height{
		vpos := f32(i + 1) * f32(Width) / f32(height + 1)

		for j in 0..<rows[i]{
			//node := node_at_idx(root, iter)
			node := get_node_at_idx(root, iter)
			node.val.pos = [2]f32{vpos, f32(j + 1) * f32(Height)/f32(rows[i] + 1)}
			//node.val.color = rl.RED
			iter += 1
		}
	}
}


size := f32(50.0)
draw_rects :: proc(root: ^Node){
	//rl.DrawCircleV(root.val.pos, size, rl.RED)
	rl.DrawRectangleRec(get_rect(root.val.pos), root.val.color)
	for child in root.children{
		draw_rects(child)
	}
}

draw_lines :: proc(root: ^Node){
	if root.val.parent != nil{
		cpos := root.val.pos + size/2
		ppos := root.val.parent.val.pos + size/2
		rl.DrawLineV(cpos, ppos, rl.BLACK)
	}

	for child in root.children{
		draw_lines(child)
	}
}

draw_tree :: proc(root: ^Node){
	draw_lines(root)
	draw_rects(root)
}

main :: proc() {
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, context.allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)

	rl.InitWindow(1720, 1240, "my window")
	rl.SetTargetFPS(60)


	arena: vmem.Arena
	arena_alloc := vmem.arena_allocator(&arena)

	//root := new(Node, arena_alloc)
	root := create_root(arena_alloc)
	add_node(root, arena_alloc)
	add_node(root, arena_alloc)
	add_node(root, arena_alloc)
	add_node(root, arena_alloc)
	add_node(root.children[0], arena_alloc)
	generate_node_data(root)

	cur_node := root
	cur_node.val.color = rl.BLUE

	focus_child_index := -1;

	lime: rl.Color = rl.LIME;
	red: rl.Color = rl.RED;
	blue: rl.Color = rl.BLUE;

	for !rl.WindowShouldClose(){
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)

		if rl.IsKeyPressed(.Q){
			fmt.println("Amount of children of current node ", cur_node.val.pos, " is ", len(cur_node.children))
		}

		if rl.IsKeyPressed(.O) && focus_child_index == -1 && len(cur_node.children) == 0{
			add_node(cur_node, arena_alloc)
			generate_node_data(root)
			cur_node.val.color = red
			cur_node = cur_node.children[0]
			cur_node.val.color = blue 
		}

		if rl.IsKeyPressed(.ENTER) && focus_child_index == -1{
			add_node(cur_node, arena_alloc)
			generate_node_data(root)
		}
		else if rl.IsKeyPressed(.ENTER){
			for child in cur_node.children{
				child.val.color = red
			}
			cur_node = cur_node.children[focus_child_index]
			cur_node.val.color = blue
			focus_child_index = -1
		}

		if rl.IsKeyPressed(.L){
			if len(cur_node.children) == 0{
				fmt.println("no children")
			}
			else if len(cur_node.children) == 1{
				cur_node.val.color = red
				cur_node = cur_node.children[0]
				cur_node.val.color = blue
			}
			else{
				for child in cur_node.children{
					child.val.color = lime 
				}
				focus_child_index = 0;
				cur_node.val.color = red 
			}
		}

		if rl.IsKeyPressed(.J){
			if cur_node.val.parent != nil{
				cur_node.val.color = red 
				cur_node  = cur_node.val.parent
				cur_node.val.color = blue
			}
		}

		if focus_child_index != -1 && rl.IsKeyPressed(.K){
			next_idx := focus_child_index + 1
			if next_idx >= len(cur_node.children){
				next_idx = 0
			}
			cur_node.children[focus_child_index].val.color = lime
			focus_child_index = next_idx
		}

		//drawing section
		draw_tree(root)


		if focus_child_index != -1{
			cur_node.children[focus_child_index].val.color = blue;
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
	vmem.arena_destroy(&arena)

	for key, value in tracking_allocator.allocation_map {
		fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
	}
}