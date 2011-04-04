# roogle_graphics is a Ruby module that renders simple text and shapes
# into .png graphics by calling the Google Chart web service.
#
# Note: roogle_graphics largely subverts the Google Chart API's
# intented function of generating charts from quantitative data.  If
# you want to generate quantitative plots, please refer to:
#
# http://code.google.com/apis/chart/docs/chart_params.html
#
# Author::    Robert Poor (rdpoor atsign gmail point com)
# Copyright:  Copyright (C) 2011 Robert Poor
# License::   Distributed under the MIT License (see LICENSE)

require 'cgi'

module RoogleGraphics

  GOOGLE_CHART_SERVICE = "http://chart.apis.google.com/chart" # :nodoc:

  # ================================================================
  # base class for any plottable element
  class GraphicElement          # :nodoc:
    attr_reader :origin_x, :origin_y

    def initialize(origin_x, origin_y)
      @origin_x, @origin_y = origin_x, origin_y
    end
  end

  # ================================================================
  # A Shape element defines a closed polygon to be rendered.
  class Shape < GraphicElement
    attr_reader :points, :outline_color, :fill_color

    # Define a new shape, to be rendered at +origin_x+, +origin_y+.  
    # +points+ is an array of x,y pairs, where each xy pair is an 
    # offset from +origin_x+, +origin_y+, as in:
    #   [[x0,y0],[x1,y1],[x2,y2], ...[x0,y0]].
    #
    # Recognized options:
    # +outline_color+:: the color of the shape's outline, as a six-character hex string.  Default is nil (no outline).
    # +fill_color+:: the fill color for the shape as a six-character hex string.  Default is nil (no fill).
    # 
    def initialize(origin_x, origin_y, points, opts = {})
      super(origin_x, origin_y)
      @points = points || []
      @outline_color = opts[:outline_color]
      @fill_color = opts[:fill_color]
      # make sure polygon is closed
      @points << @points.first unless (@points.first == @points.last)
    end
  end

  # ================================================================
  # A Text element defines a string to be rendered.
  class Text < GraphicElement
    attr_reader :text, :size, :color, :halign, :valign

    HALIGN = {:left => 'l', :center => 'h', :right => 'r'}
    VALIGN = {:bottom => 'b', :middle => 'v', :top => 't'}

    # Define a new text object to be rendered at +origin_x+, +origin_y+.
    # The alignment of the text is further controlled by the +halign+ and
    # +valign+ options below.
    #
    # Recognized options:
    # +size+:: The size of the text in pixels
    # +color+:: The color of the text as a six-character hex string.  Default is '000000' (black).
    # +halign+:: The horizontal alignment.  Valid values are (:left | :center | :right)
    # +valign+:: The vertical alignment.  Valid values are (:bottom | :middle | :top)
    def initialize(origin_x, origin_y, text, opts = {})
      super(origin_x, origin_y)
      @text = text || ""
      @size = opts[:size] || 12
      @color = opts[:color] || '000000'
      @halign = opts[:halign] || :left
      @valign = opts[:valign] || :bottom
    end

    def alignment               # :nodoc:
      HALIGN[self.halign] + VALIGN[self.valign]
    end

  end

  # ================================================================
  # Plot is the container that plots individual GraphicElements.
  class Plot
    attr_reader :width, :height, :fill_color1, :fill_color2, :angle
    attr_accessor :elements

    # Create a new, empty Plot object to which you can add Text and Shape elements.
    # Recognized options are:
    # +:width+:: width of the plot in pixels (default: 300)
    # +:height+:: height of the plot in pixels (default: 300)
    # +:fill_color1+:: primary fill color as 6-char hex string.  (default: 'ffffff', i.e. white)
    # +:fill_color2+:: gradient fill color. (default: :fill_color1)
    # +:angle+:: gradient fill angle in degrees (default: 0, i.e. left to right)
    #
    def initialize(opts = {})
      @width = opts[:width] || 300
      @height = opts[:height] || 300
      @elements = []
      @fill_color1 = opts[:fill_color1] || 'ffffff'
      @fill_color2 = opts[:fill_color2]
      @angle = opts[:angle] || 0
    end

    # Push a new graphic element (Text or Shape) on to the display
    # list.  In general, elements are drawn in the order they are
    # added, so the last element to be added is always drawn on top.
    def add_element(element)
      elements << element
    end

    # Emit a URI, suitable as an HTTP GET command, that will return
    # the graphic, generated courtesy of Google's graphing web
    # service.
    def generate_uri
      [GOOGLE_CHART_SERVICE + '?cht=lxy',
       generate_dimensions,
       inhibit_axes,
       generate_line_colors,
       generate_lines,
       generate_markers,
       generate_background
      ].join('&')
    end
    
    # Generate a string suitable for embedding in an IMG tag, for example:
    #   "<img #{plot.generate_img_uri} />"
    def generate_img_uri
      %{src="#{self.generate_uri}" width="#{self.width}" height="#{self.height}"}
    end
    
    # ================
    private

    def generate_dimensions
      "chs=#{self.width}x#{self.height}"
    end
    
    def inhibit_axes
      ["chxt=x,y",                              # axes: 0=x, 1=y
       "chxs=0,000000,0,0,_|1,000000,0,0,_",    # inhibit x and y axes
      ].join('&')
    end
    
    def generate_line_colors
      outline_colors = shape_elements.map {|s| s.outline_color}
      if (outline_colors.all? {|c| c.nil?})
        "chco=ffffff00"                # use transparent outlines
      elsif (outline_colors[1,outline_colors.size-1].all? {|c| c=outline_colors.first})
        "chco=#{outline_colors.first}" # all shape elements have the same color
      else
        "chco=" + outline_colors.join('|')
      end
    end
    
    def generate_lines
      shape_coords = shape_elements.map {|s| generate_shape(s)}.compact.join('|')
      "chd=t:" + ((shape_coords.empty?) ? "0|0" : shape_coords)
    end
    
    def generate_markers
      s = shape_elements.map {|s| s.fill_color}.zip(0..shape_elements.size).map {|c,i| "B,#{c},#{i},0,0"}
      t = text_elements.map {|t| "@t#{escape(t.text)},#{t.color},0,#{p2r_x(t.origin_x)}:#{p2r_y(t.origin_y)},#{t.size},0,#{t.alignment}"}
      "chm=" + [*s, *t].compact.join('|')
    end
    
    def generate_shape(shape)
      x_points = shape.points.map {|px, py| p2c_x(px + shape.origin_x)}
      y_points = shape.points.map {|px, py| p2c_y(py + shape.origin_y)}
      x_points.join(',')+'|'+y_points.join(',')
    end
    
    def generate_background
      if (self.fill_color2.nil? || (self.fill_color1 == self.fill_color2))
        ["chf=bg,s,#{self.fill_color1}"]
      else
        ["chf=bg,lg,#{self.angle},#{self.fill_color1},0,#{self.fill_color2},1"]
      end
    end
    
    # ================

    def shape_elements
      self.elements.select {|e| e.kind_of?(Shape)}
    end

    def text_elements
      self.elements.select {|e| e.kind_of?(Text)}
    end
      
    # map from pixel to chart coordinates
    def p2c_x(px)
      sprintf("%0.1f", lerp(px, 0.0, self.width, 0, 100.0))
    end
    
    def p2c_y(py)
      sprintf("%0.1f", lerp(py, 0.0, self.height, 0, 100.0))
    end
    
    # map from pixel to relative coordinates
    def p2r_x(px)
      sprintf("%0.3f", lerp(px, 0.0, self.width, 0.0, 1.0))
    end
    
    def p2r_y(py)
      sprintf("%0.3f", lerp(py, 0.0, self.height, 0.0, 1.0))
    end
    
    # linear interpolate: x => (x0 .. x1), f(x) => (u0 .. u1)
    def lerp(x, x0, x1, u0, u1)
      u0 + ((x-x0) * (u1-u0))/(x1-x0)
    end
    
    # escaped text for chm= style data requires that commas are escaped
    # with a backslash
    def escape(text)
      CGI::escape(text.gsub(',','\,'))
    end
    
  end

end

