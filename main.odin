package main

import "core:fmt"
import "core:mem"
import vmem "core:mem/virtual"
import "core:math/rand"
import "core:strings"

import rl "vendor:raylib"

Width :: 1720
Height :: 1240

Node :: struct{
	val: [2]f32,
	left: ^Node,
	right: ^Node,
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

	for i in 0..<columns{
		vpos := f32(i + 1) * f32(Width) / f32(columns + 1)

		for j in 0..<rows[i]{
			append(&points, [2]f32{vpos, f32(j + 1) * f32(Height)/f32(rows[i] + 1)})
		}
	}
	delete(rows)

	return points
}

generate_tree :: proc(node_count: int, alloc := context.allocator) -> ^Node{
	if node_count <= 0{
		assert(false, "at least one node needed")
	}

	root := new(Node, alloc) 

	for i in 0..<node_count - 1{
		add_node(root, {f32(i + 1), f32(i + 1)}, alloc)
	}

	height := find_height(root) + 1
	rows := node_count_for_each_level(root)

	iter := 0
	for i in 0..<height{
		vpos := f32(i + 1) * f32(Width) / f32(height + 1)

		for j in 0..<rows[i]{
			val := [2]f32{vpos, f32(j + 1) * f32(Height)/f32(rows[i] + 1)}
			add_val_to_node(root, iter, val)
			iter += 1
		}
	}

	delete(rows)
	return root
}

find_height :: proc(root: ^Node) -> int{
	if root == nil{
		return -1
	}
	return max(find_height(root.left), find_height(root.right)) + 1
}

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

add_node :: proc(root: ^Node, val: [2]f32, allocator: mem.Allocator){
	queue: Queue(^Node)

	queue_push(&queue, root)
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		if cur_node.left == nil{
			new_node := new(Node, allocator)
			new_node.val = val

			cur_node.left = new_node
			break
		}
		else{
			queue_push(&queue, cur_node.left)
		}

		if cur_node.right == nil{
			new_node := new(Node, allocator)
			new_node.val = val

			cur_node.right = new_node
			break
		}	
		else{
			queue_push(&queue, cur_node.right)
		}
	}

	delete(queue.data)
}

add_val_to_node :: proc(root: ^Node, i: int, val: [2]f32){
	if root == nil{
		return
	}
	iter := 0

	queue: Queue(^Node)
	queue_push(&queue, root)
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		if iter == i{
			cur_node.val = val

			delete(queue.data)
			return
		}
		iter += 1

		if cur_node.left != nil{
			queue_push(&queue, cur_node.left)
		}
		if cur_node.right != nil{
			queue_push(&queue, cur_node.right)
		}
	}
	delete(queue.data)
}

print :: proc(root: ^Node){
	if root == nil{
		return
	}

	queue: Queue(^Node)
	queue_push(&queue, root)
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)
		fmt.println(cur_node.val)

		if cur_node.left != nil{
			queue_push(&queue, cur_node.left)
		}
		if cur_node.right != nil{
			queue_push(&queue, cur_node.right)
		}
	}
	delete(queue.data)
}

node_count_for_each_level :: proc(root: ^Node) -> [dynamic]int{
	if root == nil{
		return {}
	}

	NodePointerDepth :: struct{
		node: ^Node,
		depth: int,
	}

	queue: Queue(NodePointerDepth)
	queue_push(&queue, NodePointerDepth{root, 0})

	depth_count: [dynamic]int
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		if cur_node.depth == len(depth_count){
			append(&depth_count, 1)
		}
		else{
			depth_count[cur_node.depth] += 1;
		}

		if cur_node.node.left != nil{
			queue_push(&queue, NodePointerDepth{cur_node.node.left, cur_node.depth + 1})
		}
		if cur_node.node.right != nil{
			queue_push(&queue, NodePointerDepth{cur_node.node.right, cur_node.depth + 1})
		}
	}
	delete(queue.data)

	return depth_count
}

draw_points :: proc(root: ^Node){
	if root == nil{
		return
	}

	queue: Queue(^Node)
	queue_push(&queue, root)
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		rl.DrawCircleV(cur_node.val, 10.0, rl.BLUE)

		if cur_node.left != nil{
			queue_push(&queue, cur_node.left)
		}
		if cur_node.right != nil{
			queue_push(&queue, cur_node.right)
		}
	}
	delete(queue.data)
}

main :: proc() {
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, context.allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)

	rl.InitWindow(1720, 1240, "my window")
	rl.SetTargetFPS(60)


	arena: vmem.Arena
	arena_alloc := vmem.arena_allocator(&arena)

	node_count := 10
	root := generate_tree(node_count, arena_alloc)

	for !rl.WindowShouldClose(){
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)

		if rl.IsKeyPressed(.J){
			vmem.arena_destroy(&arena)
			node_count += 1
			root := generate_tree(node_count, arena_alloc)
		}

		if rl.IsKeyPressed(.L){
			vmem.arena_destroy(&arena)
			node_count -= 1
			root := generate_tree(node_count, arena_alloc)
		}

		draw_points(root)

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

