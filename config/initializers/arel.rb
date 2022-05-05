# Monkeypatch for https://github.com/activerecord-hackery/squeel/issues/376
module Arel
  module Predications
    private

    def grouping_any method_id, others, *extras
      return Nodes::False.new if others.empty?

      nodes = others.map { |expr| send(method_id, expr, *extras) }
      Nodes::Grouping.new nodes.reduce { |memo, node| Nodes::Or.new(memo, node) }
    end

    def grouping_all method_id, others, *extras
      return Nodes::True.new if others.empty?

      nodes = others.map { |expr| send(method_id, expr, *extras) }
      Nodes::Grouping.new Nodes::And.new(nodes)
    end
  end
end
