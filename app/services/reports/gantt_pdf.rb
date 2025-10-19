require "prawn"

module Reports
  class GanttPdf
    include ActionView::Helpers::NumberHelper

    PAGE_MARGIN = 36
    HEADER_HEIGHT = 40
    FOOTER_HEIGHT = 30
    BAR_HEIGHT = 18
    BAR_GAP = 12
    LEFT_COLUMN_WIDTH = 200

    def initialize(project, activities, timeline_start, timeline_end)
      @project = project
      @activities = activities
      @timeline_start = timeline_start
      @timeline_end = timeline_end
      @total_days = [(timeline_end - timeline_start).to_i + 1, 1].max
    end

    def render
      pdf = ::Prawn::Document.new(page_layout: :landscape, margin: PAGE_MARGIN)
      draw_header(pdf)
      draw_footer(pdf)
      draw_timeline(pdf)
      pdf.render
    end

    private

    attr_reader :project, :activities, :timeline_start, :timeline_end, :total_days

    def draw_header(pdf)
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: HEADER_HEIGHT) do
        pdf.text project.name, size: 20, style: :bold
        pdf.move_down 4
        info = []
        info << "Owner: #{project.owner.email}" if project.owner
        info << "Generated: #{I18n.l(Time.current, format: :long)}"
        pdf.text info.join("  •  "), size: 10, color: "555555"
      end
      pdf.move_down 10
    end

    def draw_footer(pdf)
      pdf.number_pages "Page <page> of <total>", at: [pdf.bounds.left, PAGE_MARGIN / 2], size: 9
    end

    def draw_timeline(pdf)
      y_cursor = nil
      column_x = pdf.bounds.left
      grid_width = pdf.bounds.width - LEFT_COLUMN_WIDTH
      day_width = grid_width / total_days.to_f

      if activities.any?
        draw_timeline_header(pdf, column_x, grid_width, day_width)
        y_cursor = pdf.cursor

        activities.each do |activity|
          if y_cursor < FOOTER_HEIGHT + BAR_HEIGHT
            pdf.start_new_page
            draw_header(pdf)

            column_x = pdf.bounds.left
            grid_width = pdf.bounds.width - LEFT_COLUMN_WIDTH
            day_width = grid_width / total_days.to_f

            draw_timeline_header(pdf, column_x, grid_width, day_width)
            y_cursor = pdf.cursor
          end

          draw_activity_row(pdf, activity, column_x, grid_width, day_width, y_cursor)
          y_cursor -= (BAR_HEIGHT + BAR_GAP)
        end
      else
        draw_timeline_header(pdf, column_x, grid_width, day_width)
      end

      summary_cursor = y_cursor || pdf.cursor
      pdf.move_cursor_to(summary_cursor)
      pdf.move_down 20
      draw_project_summary(pdf)
    end

    def draw_timeline_header(pdf, column_x, grid_width, day_width)
      pdf.bounding_box([column_x, pdf.cursor], width: LEFT_COLUMN_WIDTH, height: 20) do
        pdf.text "Activity", size: 12, style: :bold
      end
      pdf.bounding_box([column_x + LEFT_COLUMN_WIDTH, pdf.cursor], width: grid_width, height: 20) do
        pdf.stroke_color "DDDDDD"
        total_days.times do |i|
          x_pos = i * day_width
          pdf.stroke_line [x_pos, pdf.bounds.top], [x_pos, pdf.bounds.bottom]
          if (timeline_start + i).day == 1
            pdf.draw_text (timeline_start + i).strftime("%b %Y"), at: [x_pos + 2, pdf.bounds.top + 12], size: 9
          end
        end
        pdf.stroke_horizontal_rule
      end
      pdf.move_down 10
    end

    def draw_activity_row(pdf, activity, column_x, grid_width, day_width, y_cursor)
      pdf.bounding_box([column_x, y_cursor], width: LEFT_COLUMN_WIDTH, height: BAR_HEIGHT + BAR_GAP) do
        pdf.text activity.title, size: 10, style: :bold
        pdf.move_down 2
        meta = []
        meta << (activity.assignee&.email || "Unassigned")
        if activity.start_on && activity.due_on
          meta << "#{I18n.l(activity.start_on)} – #{I18n.l(activity.due_on)}"
        end
        pdf.text meta.join("  •  "), size: 8, color: "666666"
      end

      pdf.bounding_box([column_x + LEFT_COLUMN_WIDTH, y_cursor], width: grid_width, height: BAR_HEIGHT + BAR_GAP) do
        draw_activity_bar(pdf, activity, day_width)
      end
    end

    def draw_activity_bar(pdf, activity, day_width)
      return unless activity.start_on

      start_day = [(activity.start_on - timeline_start).to_i, 0].max
      due_date = activity.due_on || activity.start_on
      end_day = [(due_date - timeline_start).to_i, 0].max
      span_days = [end_day - start_day + 1, 1].max

      bar_x = start_day * day_width
      bar_width = span_days * day_width

      pdf.fill_color "2c9cdb"
      pdf.fill_rounded_rectangle [bar_x, pdf.cursor], bar_width, BAR_HEIGHT, 4
      pdf.fill_color "ffffff"
      label = [activity.zone&.name, activity.discipline&.name].compact.join(" • ")
      pdf.draw_text label, at: [bar_x + 4, pdf.cursor - (BAR_HEIGHT / 2) + 4], size: 8 if label.present?
      pdf.fill_color "000000"
    end

    def draw_project_summary(pdf)
      pdf.stroke_color "DDDDDD"
      pdf.stroke_horizontal_rule
      pdf.move_down 10
      pdf.text "Project summary", size: 12, style: :bold
      pdf.move_down 6

      summary_items = [
        ["Owner", project.owner&.email || "-"],
        ["Activities", activities.count],
        ["Start date", activities.map(&:start_on).compact.min&.to_fs(:long) || "-"],
        ["Finish date", activities.map(&:due_on).compact.max&.to_fs(:long) || "-"],
      ]

      summary_items.each do |label, value|
        pdf.text "#{label}: <b>#{value}</b>", inline_format: true, size: 9
        pdf.move_down 4
      end

      pdf.move_down 8
      pdf.text "Generated at #{I18n.l(Time.current, format: :long)}", size: 8, color: "666666"
    end
  end
end
