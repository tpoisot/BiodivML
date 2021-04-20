colour_palette = Scale.color_discrete_manual(
    colorant"#e69f00",
    colorant"#56b4e9",
    colorant"#009e73",
    colorant"#f0e442",
    colorant"#0072b2",
    colorant"#d55e00",
    colorant"#cc79a7"
)


paper_theme = Gadfly.Theme(
    panel_stroke = colorant"#000000",
    panel_fill = colorant"#ffffff",
    panel_line_width = 0.5mm,
    plot_padding = [4mm],
    grid_color = colorant"#dcdedf",
    grid_line_style = :solid,
    major_label_color = colorant"#222222",
    minor_label_color = colorant"#000000",
    key_label_color = colorant"#000000",
    key_title_color = colorant"#000000",
    guide_title_position = :center,
    colorkey_swatch_shape = :circle,
    key_position = :right,
    key_title_font_size = 0mm,
    discrete_color_scale = colour_palette
)

Gadfly.push_theme(paper_theme)