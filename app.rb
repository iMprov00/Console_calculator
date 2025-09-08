require 'fiddle'
require 'fiddle/import'
require 'colorize'

class KeyboardHandler
  # Импортируем функции из msvcrt.dll
  module Console
    extend Fiddle::Importer
    dlload 'msvcrt.dll'
    extern 'int _kbhit()'
    extern 'int _getch()'
  end

  # Коды специальных клавиш
  SPECIAL_KEYS = {
    72 => :up,
    80 => :down,
    75 => :left,
    77 => :right,
    13 => :enter,
    27 => :escape,
    9 => :tab,
    8 => :backspace
  }

  # Буквенные клавиши
  LETTER_KEYS = {
    'a' => :a, 'A' => :a,
    'b' => :b, 'B' => :b,
    'c' => :c, 'C' => :c,
    'd' => :d, 'D' => :d,
    'e' => :e, 'E' => :e,
    'f' => :f, 'F' => :f,
    'g' => :g, 'G' => :g,
    'h' => :h, 'H' => :h,
    'i' => :i, 'I' => :i,
    'j' => :j, 'J' => :j,
    'k' => :k, 'K' => :k,
    'l' => :l, 'L' => :l,
    'm' => :m, 'M' => :m,
    'n' => :n, 'N' => :n,
    'o' => :o, 'O' => :o,
    'p' => :p, 'P' => :p,
    'q' => :q, 'Q' => :q,
    'r' => :r, 'R' => :r,
    's' => :s, 'S' => :s,
    't' => :t, 'T' => :t,
    'u' => :u, 'U' => :u,
    'v' => :v, 'V' => :v,
    'w' => :w, 'W' => :w,
    'x' => :x, 'X' => :x,
    'y' => :y, 'Y' => :y,
    'z' => :z, 'Z' => :z
  }

  def initialize
    @callbacks = {}
    @running = false
  end

  # Регистрация обработчика для клавиши
  def on(key, &block)
    @callbacks[key] = block
  end

  # Запуск прослушивания клавиш
  def start
    @running = true
    puts "Обработчик клавиатуры запущен (Ctrl+C для выхода)..."

    loop do
      break unless @running
      process_input
      sleep 0.01
    end
  end

  # Остановка прослушивания
  def stop
    @running = false
  end

  private

  def process_input
    return unless Console._kbhit() != 0

    key = Console._getch()
    key_symbol = nil

    # Обработка специальных клавиш (стрелки и т.д.)
    if key == 0 || key == 224
      key2 = Console._getch()
      key_symbol = SPECIAL_KEYS[key2]
     # puts "Специальная клавиша: #{key_symbol} (код: #{key2})" if key_symbol
    else
      # Обработка обычных клавиш
      char = key.chr
      key_symbol = SPECIAL_KEYS[key] || LETTER_KEYS[char] || char.to_sym
      
      if LETTER_KEYS[char]
       # puts "Буквенная клавиша: #{key_symbol}"
      elsif SPECIAL_KEYS[key]
        #puts "Специальная клавиша: #{key_symbol}"
      else
       # puts "Другая клавиша: #{char.inspect} (код: #{key})"
      end
    end

    # Вызов зарегистрированного обработчика
    if key_symbol && @callbacks[key_symbol]
      @callbacks[key_symbol].call(key_symbol)
    end
  end
end

class DrawingCalculator
  attr_reader :calculator

  def initialize
    draw_calculator
    @x = 2
  end


  def draw_calculator
    calculator = Array.new(8)
    calculator[0] = ["┌"] + (["─"] * 15) + ["┐"]
    calculator[1] = ["│"] + ([" "] * 15) + ["│"]  
    calculator[2] = ["│"] + (["─"] * 15) + ["│"]
    calculator[3] = ["│"] + [" "] + ["7"] + ([" "] * 3) + ["8"] + ([" "] * 3) + ["9"] + ([" "] * 3) + ["+"] + [" "] + ["│"]
    calculator[4] = ["│"] + [" "] + ["4"] + ([" "] * 3) + ["5"] + ([" "] * 3) + ["6"] + ([" "] * 3) + ["-"] + [" "] + ["│"]
    calculator[5] = ["│"] + [" "] + ["1"] + ([" "] * 3) + ["2"] + ([" "] * 3) + ["3"] + ([" "] * 3) + ["*"] + [" "] + ["│"]
    calculator[6] = ["│"] + [" "] + ["0"] + ([" "] * 3) + ["."] + ([" "] * 3) + ["="] + ([" "] * 3) + ["/"] + [" "] + ["│"]
    calculator[7] = ["└"] + (["─"] * 15) + ["┘"]

      # "┌────────────────┐",
      # "│                │",
      # "├────────────────┤",
      # "│ 7   8   9   +  │",
      # "│ 4   5   6   -  │",
      # "│ 1   2   3   *  │",
      # "│ 0   .   =   /  │",
      # "└────────────────┘"

      @calculator = calculator
  end

  def cursor(value)
    value.on_white.black
  end

  def result(y, x)
    @calculator[1][@x] = @calculator[y][x]
    @x += 1
  end

  def clear
    @calculator[1] = ["│"] + ([" "] * 15) + ["│"] 
  end

end #end class

class BorderLimit
  attr_reader :max_x, :max_y, :min_x, :min_y

  def initialize
    @max_y = 6
    @min_y = 3

    @max_x = 14
    @min_x = 2
  end

end

class EmptyElement

  def initialize(calculator)
    @calculator = calculator
  end

  def element?(y, x)
    @calculator.calculator[y][x] == " " ? true : false
  end

end

class CursorNavigator
  attr_accessor :y, :x

  def initialize(border, empty)
    @x = 2
    @y = 5
    @border = border
    @empty = empty
  end

  def move_up
    @y = [@y - 1, @border.min_y].max
  end

  def move_down
    @y = [@y + 1, @border.max_y].min
  end

  def move_left  
    if (@x - 1) < @border.min_x
      @x = @border.min_x
    else
      @x -= 1
      loop do 
        @empty.element?(@y, @x) == true ? @x = [@x - 1, @border.min_x].max : break
      end
    end
  end

  def move_right
    if (@x + 1) > @border.max_x
      @x = @border.max_x
    else
      @x += 1
      loop do 
        @empty.element?(@y, @x) == true ? @x = [@x + 1, @border.min_x].max : break
      end
    end
  end


end #end class

  # Создаем обработчик
  keyboard = KeyboardHandler.new

  draw = DrawingCalculator.new

  border = BorderLimit.new

  empty = EmptyElement.new(draw)

  cursor = CursorNavigator.new(border, empty)



loop do





  keyboard.on(:up) {cursor.move_up}
  keyboard.on(:down) {cursor.move_down}
  keyboard.on(:left) {cursor.move_left}
  keyboard.on(:right) {cursor.move_right}
  keyboard.on(:enter) {draw.result(cursor.y, cursor.x)}
  keyboard.on(:c) {draw.clear}

  # Регистрируем обработчики для клавиш
  keyboard.on(:a) do 


    puts "y: #{cursor.y}"
    puts "x: #{cursor.x}"
    puts


    arr = draw.calculator

    arr.each_with_index do |v1, i1| 
      arr[i1].each_with_index do |v2, i2|
        if cursor.y == i1 && cursor.x == i2

          print draw.cursor(v2)
        else
          print v2
        end #end if
      end 
      puts
    end
  end

  # Запускаем обработчик
  keyboard.start

end