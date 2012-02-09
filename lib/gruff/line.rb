
require File.dirname(__FILE__) + '/base'

##
# Here's how to make a Line graph:
#
#   g = Gruff::Line.new
#   g.title = "A Line Graph"
#   g.data 'Fries', [20, 23, 19, 8]
#   g.data 'Hamburgers', [50, 19, 99, 29]
#   g.write("test/output/line.png")
#
# There are also other options described below, such as #baseline_value, #baseline_color, #hide_dots, and #hide_lines.

class Gruff::Line < Gruff::Base

  # Draw a dashed line at the given value
  attr_accessor :baseline_value

  # Color of the baseline
  attr_accessor :baseline_color
  
  # Dimensions of lines and dots; calculated based on dataset size if left unspecified
  attr_accessor :line_width
  attr_accessor :dot_radius

  # Hide parts of the graph to fit more datapoints, or for a different appearance.
  attr_accessor :hide_dots, :hide_lines, :hide_values, :hide_exeeding

  # Call with target pixel width of graph (800, 400, 300), and/or 'false' to omit lines (points only).
  #
  #  g = Gruff::Line.new(400) # 400px wide with lines
  #
  #  g = Gruff::Line.new(400, false) # 400px wide, no lines (for backwards compatibility)
  #
  #  g = Gruff::Line.new(false) # Defaults to 800px wide, no lines (for backwards compatibility)
  #
  # The preferred way is to call hide_dots or hide_lines instead.
  def initialize(*args)
    raise ArgumentError, "Wrong number of arguments" if args.length > 2
    if args.empty? or ((not Numeric === args.first) && (not String === args.first)) then
      super()
    else
      super args.shift
    end

    @hide_dots = @hide_lines = @hide_exeeding = false
    @hide_values = true
    @baseline_color = 'red'
    @baseline_value = nil
  end

  def interpolate_x(xa, ya, xb, yb, y)
    return xa+((xb-xa)*(y-ya)/(yb-ya)) unless (yb-ya)==0
    return 0
  end

  def draw
    super

    return unless @has_data

    # Check to see if more than one datapoint was given. NaN can result otherwise.
    @x_increment = (@column_count > 1) ? (@graph_width / (@column_count - 1).to_f) : @graph_width

    if (defined?(@norm_baseline)) then
      level = @graph_top + (@graph_height - @norm_baseline * @graph_height)
      @d = @d.push
      @d.stroke_color @baseline_color
      @d.fill_opacity 0.0
      @d.stroke_dasharray(10, 20)
      @d.stroke_width 5
      @d.line(@graph_left, level, @graph_left + @graph_width, level)
      @d = @d.pop
    end

    @norm_data.each_with_index do |data_row, data_row_index|
      prev_x = prev_y = nil

      @one_point = contains_one_point_only?(data_row)

      data_row[DATA_VALUES_INDEX].each_with_index do |data_point, index|
        next if data_point.nil?

        raw_y = @data[data_row_index][DATA_VALUES_INDEX][index]
        tmp_y = nil
        y_exeeded = (maximum_value < raw_y || raw_y < minimum_value) && @hide_exeeding
        print " raw y " + raw_y.to_s + " max " + maximum_value.to_s + " min " + minimum_value.to_s +  " exeeds = " + y_exeeded.to_s +  "\n"

        
        real_x = new_x = @graph_left + (@x_increment * index)
        real_y = new_y = @graph_top + (@graph_height - data_point * @graph_height)
        ann_y = new_y + 10
        
        if y_exeeded then # adjust new x and y if y is over limits
          if raw_y > maximum_value then
            tmp_y = @graph_top
            ann_y = tmp_y - 10
          else
            tmp_y = @graph_top + @graph_height
            ann_y = tmp_y - 100
          end
          print " new x= " + new_x.to_s  + " new_y = " + new_y.to_s + " prev x = " + prev_x.to_s + " prev y = " + prev_y.to_s + "\n"
          if prev_x.nil? or prev_y.nil? then # first datapoint
            new_x = interpolate_x(@graph_left, tmp_y, new_x, new_y, tmp_y)
          else # normal case
            new_x = interpolate_x(prev_x, prev_y, new_x, new_y, tmp_y)
          end
          new_y = tmp_y
        end
        

        draw_label(new_x, index)

        # Reset each time to avoid thin-line errors
        @d = @d.stroke data_row[DATA_COLOR_INDEX]
        @d = @d.fill data_row[DATA_COLOR_INDEX]
        @d = @d.stroke_opacity 1.0
        @d = @d.stroke_width line_width ||
          clip_value_if_greater_than(@columns / (@norm_data.first[DATA_VALUES_INDEX].size * 4), 5.0)


        circle_radius = dot_radius ||
          clip_value_if_greater_than(@columns / (@norm_data.first[DATA_VALUES_INDEX].size * 2.5), 5.0)

        if !@hide_lines and !prev_x.nil? and !prev_y.nil? then
          @d = @d.line(prev_x, prev_y, new_x, new_y)
        elsif @one_point
          # Show a circle if there's just one_point
          @d = @d.circle(new_x, new_y, new_x - circle_radius, new_y)
        end
        @d = @d.circle(new_x, new_y, new_x - circle_radius, new_y) unless @hide_dots or y_exeeded
        @d = @d.annotate_scaled(@base_image,
                                1, 1,
                                real_x, ann_y + 2*circle_radius, #prevent overlap between dot and value 
                                @data[data_row_index][DATA_VALUES_INDEX][index].to_s,
                                @scale) unless @hide_values

        
        if index < data_row.size then
          print "yli on indexi\n"
        end
        
        if y_exeeded and index+1 < data_row[DATA_VALUES_INDEX].size then
          next_x = @graph_left + (@x_increment * index+1)
          next_y = data_row[DATA_VALUES_INDEX][index+1]
          #real_x = @graph_left + (@x_increment * index)
          #real_y = @graph_top + (@graph_height - data_point * @graph_height)
          print "XX new x= " + new_x.to_s  + " new_y = " + new_y.to_s + " next x = " + next_x.to_s + " next y = " + next_y.to_s + "\n"
          prev_x = interpolate_x(real_x, real_y, next_x, next_y, new_y)
          prev_y = new_y
        else
          prev_x = new_x
          prev_y = new_y
        end
        
      end

    end

    @d.draw(@base_image)
  end

  def normalize(force=false)
    @maximum_value = [@maximum_value.to_f, @baseline_value.to_f].max
    super(force)
    @norm_baseline = (@baseline_value.to_f / @maximum_value.to_f) if @baseline_value
  end

  def contains_one_point_only?(data_row)
    # Spin through data to determine if there is just one_value present.
    one_point = false
    data_row[DATA_VALUES_INDEX].each do |data_point|
      if !data_point.nil?
        if one_point
          # more than one point, bail
          return false
        else
          # there is at least one data point
          return true
        end
      end
    end
    return one_point
  end

end
