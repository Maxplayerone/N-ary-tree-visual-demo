package main

import "core:fmt"
import "core:mem"
import vmem "core:mem/virtual"
import "core:math/rand"
import "core:strings"

import rl "vendor:raylib"

Width :: 1720
Height :: 1240

size: f32 = 50

// ------------ utils -------------
get_rect :: proc(v: [2]f32) -> rl.Rectangle{
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


//------------ N-ary tree section -----------
Node :: struct{
	val: NodeVal,
	left: ^Node,
	right: ^Node,
}

NodeVal :: struct{
	pos: [2]f32,
	color: rl.Color,
	parent_pos: [2]f32,
}

find_height :: proc(root: ^Node) -> int{
	if root == nil{
		return -1
	}
	return max(find_height(root.left), find_height(root.right)) + 1
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

add_node :: proc(root: ^Node, val: NodeVal, allocator: mem.Allocator){
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

add_node_depth_one :: proc(root: ^Node, alloc := context.allocator) -> bool{
	added := false
	if root.left == nil{
		new_node := new(Node, alloc)
		root.left = new_node

		added = true
	}
	else if root.left != nil && root.right == nil{
		new_node := new(Node, alloc)
		root.right = new_node

		added = true
	}

	return added
}

get_parent_node :: proc(root: ^Node, child: ^Node) -> (^Node, bool){
	if root == nil{
		return {}, false
	}

	queue: Queue(^Node)
	queue_push(&queue, root)
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		if cur_node.left == child || cur_node.right == child{
			delete(queue.data)
			return cur_node, true
		}

		if cur_node.left != nil{
			queue_push(&queue, cur_node.left)
		}
		if cur_node.right != nil{
			queue_push(&queue, cur_node.right)
		}
	}
	delete(queue.data)

	return {}, false
}

node_at_idx :: proc(root: ^Node, i: int) -> ^Node{
	if root == nil{

		return {}
	}
	iter := 0

	queue: Queue(^Node)
	queue_push(&queue, root)
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		if iter == i{
			delete(queue.data)
			return cur_node
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

	return {}
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

tree_node_count :: proc(root: ^Node) -> int{
	if root == nil{
		return 0
	}
	iter := 0

	queue: Queue(^Node)
	queue_push(&queue, root)
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)
		iter += 1

		if cur_node.left != nil{
			queue_push(&queue, cur_node.left)
		}
		if cur_node.right != nil{
			queue_push(&queue, cur_node.right)
		}
	}
	delete(queue.data)
	return iter
}

draw_points :: proc(root: ^Node){
	if root == nil{
		return
	}

	queue: Queue(^Node)
	queue_push(&queue, root)
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		rl.DrawCircleV(cur_node.val.pos, 10.0, rl.BLUE)

		if cur_node.left != nil{
			queue_push(&queue, cur_node.left)
		}
		if cur_node.right != nil{
			queue_push(&queue, cur_node.right)
		}
	}
	delete(queue.data)
}

draw_rects :: proc(root: ^Node){
	if root == nil{
		return
	}

	queue: Queue(^Node)
	queue_push(&queue, root)
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		rl.DrawRectangleRec(get_rect(cur_node.val.pos), cur_node.val.color)

		if cur_node.left != nil{
			queue_push(&queue, cur_node.left)
		}
		if cur_node.right != nil{
			queue_push(&queue, cur_node.right)
		}
	}
	delete(queue.data)
}

draw_lines :: proc(root: ^Node){
	if root == nil{
		return
	}

	queue: Queue(^Node)
	queue_push(&queue, root)
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		if cur_node.val.parent_pos != {}{
			//rl.DrawRectangleRec(get_rect(cur_node.val.pos), cur_node.val.color)
			ppos := cur_node.val.parent_pos + size/2
			cpos := cur_node.val.pos + size/2
			rl.DrawLineV(ppos, cpos, rl.BLACK)
		}

		if cur_node.left != nil{
			queue_push(&queue, cur_node.left)
		}
		if cur_node.right != nil{
			queue_push(&queue, cur_node.right)
		}
	}
	delete(queue.data)
}

generate_nodes :: proc(node_count: int, alloc := context.temp_allocator) -> ^Node{
	if node_count <= 0{
		assert(false, "at least one node needed")
	}

	root := new(Node, alloc) 

	for i in 0..<node_count - 1{
		val := NodeVal{
			pos = {},
			color = rl.RED
		}
		add_node(root, val, alloc)
	}
	return root
}

generate_tree_data :: proc(root: ^Node){
	height := find_height(root) + 1
	rows := node_count_for_each_level(root)

	iter := 0
	for i in 0..<height{
		vpos := f32(i + 1) * f32(Width) / f32(height + 1)

		for j in 0..<rows[i]{
			node := node_at_idx(root, iter)
			node.val.pos = [2]f32{vpos, f32(j + 1) * f32(Height)/f32(rows[i] + 1)}
			node.val.color = rl.RED
		
			if parent, found := get_parent_node(root, node); found{
				node.val.parent_pos = parent.val.pos 
			}
			iter += 1
		}
	}

	delete(rows)
}

generate_tree :: proc(node_count: int, alloc := context.allocator) -> ^Node{
	root := generate_nodes(node_count, alloc)
	generate_tree_data(root)
	return root
}

clicked_node :: proc(root: ^Node) -> int{
	if root == nil{
		return -1 
	}

	queue: Queue(^Node)
	queue_push(&queue, root)
	iter := 0
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		if mouse_rect_collission(get_rect(cur_node.val.pos)){

			delete(queue.data)
			return iter 
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

	return -1 
}

hovering_on_node :: proc(root: ^Node) -> int{
	if root == nil{
		return -1 
	}

	queue: Queue(^Node)
	queue_push(&queue, root)
	iter := 0
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)

		if mouse_rect_collission(get_rect(cur_node.val.pos)){

			delete(queue.data)
			return iter 
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

	return -1 
}

set_tree_color :: proc(root: ^Node, color: rl.Color){
	if root == nil{
		return
	}

	queue: Queue(^Node)
	queue_push(&queue, root)
	for len(queue.data) > 0{
		cur_node := queue_pop(&queue)
		cur_node.val.color = color

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
	fmt.println(tree_node_count(root))

	for !rl.WindowShouldClose(){
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)

		if rl.IsKeyPressed(.J){
			vmem.arena_destroy(&arena)
			node_count += 1
			root := generate_tree(node_count, arena_alloc)
		}

		if rl.IsMouseButtonPressed(.LEFT){
			if idx := clicked_node(root); idx != -1{
				node := node_at_idx(root, idx)
				added := add_node_depth_one(node, arena_alloc)
				if added{
					fmt.println("addition was successful")
					fmt.println(tree_node_count(root))
					generate_tree_data(root)
				}
				else{
					fmt.println("addition was unsuccessful")
				}
			}
		}
		set_tree_color(root, rl.RED)
		if idx := hovering_on_node(root); idx != -1{
			node := node_at_idx(root, idx)
			node.val.color = rl.BLUE
		}

		if rl.IsKeyPressed(.L){
			vmem.arena_destroy(&arena)
			node_count -= 1
			root := generate_tree(node_count, arena_alloc)
		}

		draw_lines(root)
		draw_rects(root)

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