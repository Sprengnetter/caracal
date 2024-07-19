module Caracal
  module Renderers
    module RenderHelpers

      def render_margins(w, model, margin_type, type)
        margins = %w(top left bottom right).select do |dir|
          v = model.send "#{type}_#{dir}"
          not v.nil?
        end

        if margins.any?
          w.send margin_type do
            margins.each do |dir|
              w.send dir, 'w:w' => model.send("#{type}_#{dir}"), 'w:type' => 'dxa'
            end
          end
        end
      end

      def render_borders(w, model, border_type, type)
        borders = %w(top left bottom right horizontal vertical).select do |dir|
          method_name = "#{type}_border_#{dir}_line"
          v = model.send method_name #if model.respond_to? method_name
          v and v != :none
        end

        if borders.any?
          w.send border_type do
            borders.each do |dir|
              options = {
                'w:val'   => model.send("#{type}_border_#{dir}_line"),
                'w:sz'    => model.send("#{type}_border_#{dir}_size"),
                'w:space' => model.send("#{type}_border_#{dir}_spacing") || 0
              }
              color_opts = theme_color_options model.send("#{type}_border_#{dir}_theme_color"), model.send("#{type}_border_#{dir}_color"), 'w:color'

              w.send Caracal::Core::Models::BorderModel.formatted_type(dir), options.merge(color_opts)
            end
          end
        end
      end

      def theme_color_options(theme, color, attr)
        if theme
          attrs = {
            'w:themeColor' => theme.theme_color_ref,
            'w:themeTint'  => theme.theme_color_tint,
            'w:themeShade' => theme.theme_color_shade,
            attr           => theme.theme_color_val
          }.compact
        elsif color
          {attr => color}
        else
          {}
        end
      end

      def render_color(w, model, type = nil)
        if theme = type ? model.send("#{type}_theme_color") : model[:theme_color]
          attrs = {
            'w:themeColor' => theme.theme_color_ref,
            'w:themeTint'  => theme.theme_color_tint,
            'w:themeShade' => theme.theme_color_shade,
            'w:val'        => theme.theme_color_val
          }.compact
          w.color attrs unless attrs.empty?
        elsif color = type ? model.send("#{type}_color") : model[:color]
          if color.to_s != 'none'
            w.color 'w:val' => color
          end
        end
      end

      def render_background(w, model, type = nil)
        if theme = type ? model.send("#{type}_theme_bgcolor") : model[:theme_bgcolor]
          bgstyle = type ? model.send("#{type}_bgstyle") : model[:bgstyle]
          attrs = {
            'w:val'        => (bgstyle || 'solid'),
            'w:color'      => theme.theme_color_val,
            'w:themeColor' => theme.theme_color_ref,
            'w:themeTint'  => theme.theme_color_tint,
            'w:themeShade' => theme.theme_color_shade
          }.compact
          w.shd attrs unless attrs.empty?
        elsif color = type ? model.send("#{type}_bgcolor") : model[:bgcolor]
          if color.to_s != 'none'
            w.shd 'w:val' => 'solid', 'w:color' => color
          end
        end
      end

      def render_fonts(w, model, font_type, type = nil)
        font = type ? model.send("#{type}_font") : model[:font]
        unless font.nil?
          w.send font_type, 'w:ascii' => font, 'w:hAnsi' => font, 'w:eastAsia' => font, 'w:cs' => font
        end
      end

      def render_run_attributes(w, model, skip_empty: true)
        if model.respond_to? :run_attributes
          attrs = model.run_attributes # only contains non-nil values
          unless attrs.empty? and not skip_empty
            w.rPr do
              render_fonts w, attrs, 'rFonts'
              unless attrs.bold.nil?
                w.b       'w:val' => attrs.bold
                # w.bCs     'w:val' => attrs.bold
              end
              unless attrs.italic.nil?
                w.i       'w:val' => attrs.italic
                # w.iCs     'w:val' => attrs.italic
              end
              w.caps       'w:val' => attrs.caps                            unless attrs.caps.nil?
              w.smallCaps  'w:val' => attrs.small_caps                      unless attrs.small_caps.nil?
              w.strike     'w:val' => attrs.strike                          unless attrs.strike.nil?
              render_color  w, attrs
              w.sz         'w:val' => attrs.size                            unless attrs.size.nil?
              # w.highlight  'w:val' => attrs.highlight_color                 unless attrs.highlight_color.nil?
              w.u          'w:val' => (attrs.underline ? 'single' : 'none') unless attrs.underline.nil?
              # TODO: w.bdr
              render_background w, attrs
              w.vertAlign  'w:val' => attrs.vertical_align                  unless attrs.vertical_align.nil?
              w.rtl        'w:val' => attrs.rtl                             unless attrs.rtl.nil?
              w.vanish     'w:val' => attrs.hide_mark                       unless attrs.hide_mark.nil?
              w.specVanish 'w:val' => attrs.hide_mark                       unless attrs.hide_mark.nil?
            end
          end
        end
      end

    end
  end
end
