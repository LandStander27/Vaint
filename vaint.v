module main

import os
import term
import time
import rand
import strconv

struct Point {
mut:
	x int
	y int
}

struct SleepDelay {
mut:
	delay int
}

struct Command {
	name string
	func fn ([]string) !
}

const (
	current = Point{1, 2}
	delay = SleepDelay{0}
)

fn find(value []string, pos int, str string) int {
	mut answer := -1
	str2 := str.split("")
	for i in pos..str2.len {

		if str2[i] in value {

			answer = i
			break

		}

	}
	return answer
}

fn parse(cmd_not string, vars [][]string) ![]string {
	mut cmd := cmd_not
	for i in vars {
		cmd = cmd_not.replace(i[0], i[1])
	}
	start := find(["("], 0, cmd)
	if start == -1 {
		return error("Parsing error")
	}
	middle := cmd.split("")[start+1..cmd.split("").len-1].join("")
	mut args := [cmd.split("")[..start].join("")]

	mut nest := 0
	mut mid := middle.split("")

	mut temp := ""
	if mid.len != 0 {
		for i in 0..mid.len {
			if mid[i] == "(" {
				nest++
				temp += mid[i]
			} else if mid[i] == ")" {
				nest--
				temp += mid[i]
			} else if mid[i] == "," {
				if nest == 0 {
					args << temp
					temp = ""
				} else {
					temp += mid[i]
				}

			} else {
				temp += mid[i]
			}
		}
		if nest != 0 {
			return error("Parsing error")
		}
		args << temp
	}

	// if middle.len != 0 { args << middle.split(",") }
	for mut i in args {
		i = i.trim_space()
	}

	x, y := term.get_terminal_size()

	for mut i in args {
		if i == "x" {
			i = x.str()
		} else if i == "y" {
			i = (y-2).str()
		}
	}

	return args
}

fn check_set_vars(cmd string, mut vars [][]string) bool {

	if "=" !in cmd.split("") {
		return false
	}

	start := find(["="], 0, cmd)
	name := cmd.split("")[..start].join("")
	value := cmd.split("")[start+1..cmd.split("").len].join("")
	mut is_in := false
	for mut i in vars {
		if name == i[0] {
			i[1] = value
			is_in = true
		}
	}
	if is_in == false {
		vars << [name, value]
	}
	return true

}

fn draw(p Point, color string) {
	term.set_cursor_position(term.Coord{ p.x, p.y })
	match color {
		"white" {
			println(term.bg_white(" "))
		}
		"blue" {
			println(term.bg_blue(" "))
		}
		"red" {
			println(term.bg_red(" "))
		}
		"green" {
			println(term.bg_green(" "))
		}
		"yellow" {
			println(term.bg_yellow(" "))
		}
		else {
			
		}
	}
	
}

fn convert(value string) !int {
	if isnil(value) {
		return error("Value is nil")
	}
	
	return strconv.atoi(value) or { return error("Value '$value' not integer") }
}

fn exit_handler(x os.Signal) {
	_, y := term.get_terminal_size()
	term.set_cursor_position(x: 0, y: y)
	exit(0)
}

[noreturn]
fn handle_error(err IError, num int) {
	term.clear()
	println(err.msg())
	println("Error on line: ${num+1}")
	_, y := term.get_terminal_size()
	term.set_cursor_position(x: 0, y: y)
	exit(1)
}

fn main() {

	$if !msvc {
		println("Must compile with MSVC")
		exit(1)
	}

	os.signal_opt(.int, exit_handler) or {
		println("Unable to set exit handler")
		exit(1)
	}

	term.clear()

	_, t := term.get_terminal_size()
	term.set_cursor_position(x: 0, y: t)
	print("^C to exit")
	term.set_cursor_position(x: current.x, y: current.y)

	mut commands := []Command{}

	commands << Command {name: "paint", func: fn (args []string) ! {
		if args.len == 0 {
			draw(current, "white")
			return
		}

		cols := ["white", "red", "green", "blue", "yellow", "random"]

		if args[0] !in cols {
			return error("Invalid color: ${args[0]}\nValid colors are: ${term.blue(cols.join(', '))}")
		}

		if args[0] != "random" {
			draw(current, args[0])
			return
		}

		draw(current, rand.element(cols.filter(it != "random")) or { return error("Randomizer error: $err") })
		

	}}

	commands << Command {name: "print", func: fn(args []string) ! {

		if args.len == 0 {
			return error("Nothing to print")
		}

		term.set_cursor_position(x: current.x, y: current.y)
		print(args[0])

	}}

	commands << Command {name: "up", func: fn (args []string) ! {
		if args.len != 0 {
			unsafe { current.y -= convert(args[0]) or { return err } }
			_, y := term.get_terminal_size()
			if current.y < 1 || current.y > y {
				return error("Hit a wall")
			}
		} else {
			unsafe { current.y-- }
			_, y := term.get_terminal_size()
			if current.y < 1 || current.y > y {
				return error("Hit a wall")
			}
		}
		term.set_cursor_position(x: current.x, y: current.y)


	}}

	commands << Command {name: "down", func: fn (args []string) ! {

		if args.len != 0 {

			val := convert(args[0]) or { return err }
			unsafe { current.y += val }
			_, y := term.get_terminal_size()
			if current.y < 1 || current.y > y {
				return error("Hit a wall")
			}
		} else {
			unsafe { current.y++ }
			_, y := term.get_terminal_size()
			if current.y < 1 || current.y > y {
				return error("Hit a wall")
			}
		}
		term.set_cursor_position(x: current.x, y: current.y)


	}}

	commands << Command {name: "left", func: fn (args []string) ! {
		if args.len != 0 {
			unsafe { current.x -= convert(args[0]) or { return err } }
			x, _ := term.get_terminal_size()
			if current.x < 0 || current.x > x {
				return error("Hit a wall")
			}
		} else {
			unsafe { current.x-- }
			x, _ := term.get_terminal_size()
			if current.x < 0 || current.x > x {
				return error("Hit a wall")
			}
		}
		term.set_cursor_position(x: current.x, y: current.y)


	}}

	commands << Command {name: "right", func: fn (args []string) ! {
		if args.len != 0 {

			unsafe { current.x += convert(args[0]) or { return err } }
			x, _ := term.get_terminal_size()
			if current.x < 0 || current.x > x {
				return error("Hit a wall")
			}
		} else {
			unsafe { current.x++ }
			x, _ := term.get_terminal_size()
			if current.x < 0 || current.x > x {
				return error("Hit a wall")
			}
		}
		term.set_cursor_position(x: current.x, y: current.y)


	}}

	commands << Command {name: "set_delay", func: fn (args []string) ! {

		if args.len != 1 {
			return error("Must supply an integer")
		}

		num := convert(args[0]) !

		unsafe { delay.delay = num }

	}}

	commands << Command {name: "sleep", func: fn (args []string) ! {
		if args.len != 1 {
			return error("Must supply an integer")
		}

		num := convert(args[0]) !

		time.sleep(num * time.millisecond)
	}}

	commands << Command {name: "exit", func: fn (args []string) ! {
		if args.len != 0 {
			return error("Too many arguments")
		}

		_, y := term.get_terminal_size()
		term.set_cursor_position(x: 0, y: y)
		exit(0)
		
		return error("Unable to exit")
	}}

	commands << Command {name: "set", func: fn (args []string) ! {
		help := "set(x: int, y: int)\nCan supply 'current' to not change or 'random' to randomize the x or y values"

		if args.len != 2 {
			return error("Must upply 2 arguments\n$help")
		}

		mut types := []string{cap: 2}
		for i in args {
			if _ := convert(i) {
				types << "int"
			} else {
				types << "string"
			}
		}

		for i in 0..types.len {
			if types[i] == "string" {
				if args[i] !in ["current", "random"] {
					return error("Only valid options are 'current' and 'random'")
				}
			}
		}
		x, y := term.get_terminal_size()
		if types[0] == "int" {
			unsafe { current.x = convert(args[0]) or { return err } }
		} else {
			if args[0] == "random" {
				unsafe { current.x = rand.int_in_range(1, x) or { return error("Randomizing error: $err") } }
			}
		}

		if types[1] == "int" {
			unsafe { current.y = convert(args[1]) or { return err } }
		} else {
			if args[1] == "random" {
				unsafe { current.y = rand.int_in_range(2, y) or { return error("Randomizing error: $err") } }
			}
		}

		if current.y < 1 || current.y > y {
			return error("Hit a wall")
		}
		if current.x < 0 || current.x > x {
			return error("Hit a wall")
		}

		term.set_cursor_position(x: current.x, y: current.y)

	}}

	mut ref := &commands

	commands << Command {name: "loop", func: fn [ref] (args []string) ! {

		commands := *ref

		help := "loop(action: function, delay: int (ms), loop_times: int (if not specified it will loop forever))"

		if args.len == 0 {
			return error("Not enough arguments\n" + help)
		}

		mut listed_cmds := []Command{}
		mut arguments := [][]string{}

		mut l := []string{}

		mut nest := 0
		mut temp := ""

		mut c := args[0].split("")

		for i in 0..c.len {
			if c[i] == "(" {
				nest++
				temp += c[i]
			} else if c[i] == ")" {
				nest--
				temp += c[i]
			} else if c[i] == "+" {
				if nest == 0 {
					l << temp
					temp = ""
				} else {
					temp += c[i]
				}
			} else {
				temp += c[i]
			}
		}
		if nest != 0 {
			return error("Parse error")
		}
		l << temp


		for mut i in l {
			i = i.trim_space()
		}

		for i in l {
			a := parse(i, [][]string{}) !
			mut is_cmd := false
			for cmd in commands {
				if cmd.name == a[0] {
					listed_cmds << cmd
					arguments << a[1..]
					is_cmd = true
					break
				}
			}
			if !is_cmd {
				return error("Invalid function '${a[0]}()'")
			}
		}

		// non := arguments.clone()

		if args.len == 2 {
			
			de := convert(args[1]) !

			for {
				for cmd in 0..listed_cmds.len {
					listed_cmds[cmd].func(arguments[cmd]) !
				}
				time.sleep(de * time.millisecond)
			}

		} else if args.len == 3 {

			de := convert(args[1]) !
			amount := convert(args[2]) !

			for _ in 0..amount {

				for cmd in 0..listed_cmds.len {

					// if arguments.len == 3 {
					// 	term.set_cursor_position(x: 1, y: 17)
					// 	print("${arguments}" + " ".repeat(50))
					// }
					listed_cmds[cmd].func(arguments[cmd]) !
				}
				time.sleep(de * time.millisecond)
			}

		} else {
			return error("Only 2 or 3 arguments\n" + help)
		}

	}}

	mut vars := [][]string{}
	// for {
	// 	inp := os.input(">>> ").replace(" ", "")
	// 	if check_set_vars(inp, mut vars) == false {
	// 		println(parse(inp, vars)!)
	// 	}
	// }

	if os.args.len == 1 {
		println("Must supply file")
		exit(1)
	}
	file := os.args[1]

	f := os.open(file) or { 
		println("Invalid file")
		exit(1)
	}
	data := f.read_bytes(int(os.file_size(file))).bytestr()
	
	mut formatted := data.split("\n")
	for mut i in formatted {
		i = i.trim_space()
	}
	// formatted = formatted.filter(it != "").filter(it.starts_with("//") == false)
	mut old := "On function: "
	for line_number, i  in formatted {
		if i == "" {
			continue
		}
		if i.starts_with("//") {
			continue
		}
		time.sleep(delay.delay * time.millisecond)
		// code := i.replace(" ", "")
		code := i
		// if check_set_vars(code, mut vars) == false {
		arguments := parse(code, vars) or { handle_error(err, line_number) }
		mut is_cmd := false
		for x in commands {
			if x.name == arguments[0] {
				term.set_cursor_position(x: 1, y: 1)
				mut a := "On function: $x.name"
				print(a)
				if a.len < old.len {
					print(" ".repeat(old.len - a.len))
					
				}
				old = "On function: $x.name"
				x.func(arguments[1..]) or {
					handle_error(err, line_number)
				}
				is_cmd = true
				break
			}
		}
		if !is_cmd {
			handle_error(error("Invalid function '${arguments[0]}()'"), line_number)
		}

	}
	_, y := term.get_terminal_size()
	term.set_cursor_position(x: 0, y: y)

}
