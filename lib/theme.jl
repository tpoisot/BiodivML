colour_palette = Scale.color_discrete_manual(
    colorant"#648FFF",
    colorant"#785EF0",
    colorant"#DC267F",
    colorant"#FE6100",
    colorant"#FFB000"
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
    key_position = :top,
    key_title_font_size = 0mm,
    discrete_color_scale = colour_palette
)

Gadfly.push_theme(paper_theme)