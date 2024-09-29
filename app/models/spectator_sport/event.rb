module SpectatorSport
  class Event < ApplicationRecord
    belongs_to :session
    belongs_to :session_window

    # taken from https://github.com/rrweb-io/rrweb/blob/9488deb6d54a5f04350c063d942da5e96ab74075/src/types.ts
    EVENT_TYPES = %w[DomContentLoaded Load FullSnapshot IncrementalSnapshot Meta Custom]
    EVENT_SOURCES = %w[Mutation MouseMove MouseInteraction Scroll ViewportResize Input TouchMove MediaInteraction
                       StyleSheetRule CanvasMutation Font Log Drag StyleDeclaration Selection AdoptedStyleSheet]
    MOUSE_INTERACTIONS = %w[MouseUp MouseDown Click ContextMenu DblClick Focus Blur TouchStart TouchMove_Departed
                            TouchEnd TouchCancel]

    NODE_TYPES = %w[PLACEHOLDER ELEMENT_NODE ATTRIBUTE_NODE TEXT_NODE CDATA_SECTION_NODE ENTITY_REFERENCE_NODE
                    ENTITY_NODE PROCESSING_INSTRUCTION_NODE COMMENT_NODE DOCUMENT_NODE DOCUMENT_TYPE_NODE
                    DOCUMENT_FRAGMENT_NODE]

    Explanation = Struct.new(:title, :details)

    def explanation
      explanation = Explanation.new(title, [])

      if event_type == "Meta"
        explanation.details << "visited #{event_data.dig("data", "href")}"
      end

      if event_source
        explanation.details << "source: #{event_source}"
      end

      if event_source == "MouseInteraction"
        mouse_interaction = MOUSE_INTERACTIONS[event_data.dig("data", "type")]
        explanation.details << "#{mouse_interaction}"
      end

      explanation
    end

    def event_type
      EVENT_TYPES[event_data["type"]]
    end

    def event_source
      return unless event_data.dig("data", "source")

      EVENT_SOURCES[event_data.dig("data", "source")]
    end

    def page
      event_data.dig("data", "href")
    end

    def title
      if click?
        "Mouse Click"
      else
        event_type
      end
    end

    def click?
      event_type == "IncrementalSnapshot" &&
      event_source == "MouseInteraction" &&
      MOUSE_INTERACTIONS[event_data.dig("data", "type")] == "Click"
    end

    def click_target
      return unless click?

      target_id = event_data.dig("data", "id")
      target_node = find_element_by_id(referential_full_snapshot.event_data.dig("data", "node"), target_id)
      target_node
    end

    def referential_full_snapshot
      return self if event_type == "FullSnapshot"

      session_window.events_before(self).select { _1.event_type=="FullSnapshot" }.last
    end

    def find_element_by_id(node, target_id)
      return node if node["id"].to_s == target_id.to_s

      if node.is_a?(Hash) && node["childNodes"]
        node["childNodes"].each do |child|
          result = find_element_by_id(child, target_id)
          return result unless result.nil?
        end
      elsif node.is_a?(Array)
        node.each do |child|
          result = find_element_by_id(child, target_id)
          return result unless result.nil?
        end
      end

      nil
    end
  end
end
