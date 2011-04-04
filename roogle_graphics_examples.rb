# require 'roogle_graphics.rb'

module RoogleGraphicsExamples # :nodoc:
  include RoogleGraphics
  
  def hello_world
    # create a plot object with a yellow gradient background
    plot_width = 300
    plot_height = 300
    plot = Plot.new(:width => plot_width, :height => plot_height, :fill_color2 => 'ffffcc')
    
    # add a pale blue box, centered at the middle of the plot
    shape = Shape.new(plot_width/2, plot_height/2, [[-130,-130],[130,-130],[130,130],[-130,130],[-130,-130]], :fill_color => 'ccccff')
    plot.add_element(shape)
    
    # add text with cheap embossed effect
    text = Text.new((plot_width/2)-2, (plot_height/2)-2, "hello, world!", :color => 'ffffff', :size => 40, :halign => :center, :valign => :middle)
    plot.add_element(text)
    text = Text.new(plot_width/2, plot_height/2, "hello, world!", :size => 40, :halign => :center, :valign => :middle)
    plot.add_element(text)
    
    # generate the URI that, when passed to Google, will produce the plot
    plot.generate_uri
  end
  
  def diamond_ring
    # Define a plot area with a pale gray gradient background
    plot_width = 300
    plot_height = 300
    x0 = plot_width / 2.0
    y0 = plot_height / 2.0
    plot = Plot.new(:width => plot_width, :height => plot_height, :fill_color1 => 'ffffff', :fill_color2 => 'dddddd', :angle => 90)
    
    # Add some familiar text, centered at the middle of the plot
    plot.add_element(Text.new(x0, y0, "hello, world!", :size => 30, :halign => :center, :valign => :middle))
    
    # define a diamond shape
    diamond_width = 40
    diamond_height = 60
    diamond_shape = [[0.0, -diamond_height/2], 
                     [diamond_width/2, 0.0], 
                     [0.0, diamond_height/2], 
                     [-diamond_width/2, 0.0], 
                     [0.0, -diamond_height/2]]
    
    # add five diamonds to the plot, arranged on a circle
    i_to_r = 2 * Math::PI / 5.0
    r = [x0, y0].min - diamond_width
    5.times do |i|
      # color[i] => ff0000 ff3333 ff9999 ffcccc ffffff
      color = sprintf("%02x%02x%02x", 255, i*51, i*51)
      x = x0 + r * Math.sin(i * i_to_r)
      y = y0 + r * Math.cos(i * i_to_r)
      plot.add_element(Shape.new(x, y, diamond_shape, :outline_color => '000000', :fill_color => color))
    end
    
    # Generate the URI that will produce the plot
    plot.generate_uri
  end
  
  # Demonstrate the combinations of :halign and :valign for Text objects
  def nine_monkeys
    plot_width = 200
    plot_height = 200
    plot = Plot.new(:width => plot_width, :height => plot_height)
    plot = Plot.new(:width => plot_width, :height => plot_height, :fill_color1 => 'ffdddd')
    
    text_size = 16
    text = "monkey"
    x0 = 0
    y0 = 0
    x1 = plot_width / 2.0
    y1 = plot_height / 2.0
    x2 = plot_width
    y2 = plot_height
    
    plot.add_element(Text.new(x0, y0, text, :size => text_size, :halign => :left, :valign => :bottom))
    plot.add_element(Text.new(x0, y1, text, :size => text_size, :halign => :left, :valign => :middle))
    plot.add_element(Text.new(x0, y2, text, :size => text_size, :halign => :left, :valign => :top))
    plot.add_element(Text.new(x1, y0, text, :size => text_size, :halign => :center, :valign => :bottom))
    plot.add_element(Text.new(x1, y1, text, :size => text_size, :halign => :center, :valign => :middle))
    plot.add_element(Text.new(x1, y2, text, :size => text_size, :halign => :center, :valign => :top))
    plot.add_element(Text.new(x2, y0, text, :size => text_size, :halign => :right, :valign => :bottom))
    plot.add_element(Text.new(x2, y1, text, :size => text_size, :halign => :right, :valign => :middle))
    plot.add_element(Text.new(x2, y2, text, :size => text_size, :halign => :right, :valign => :top))
    
    plot.generate_uri
  end
end
