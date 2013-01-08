module ActiveAdminImportable
  module Importer

    def self.import extension, resource, file
      result = {imported: 0, failed: 0, errors: [""]}
      resource = resource.constantize

      data =
        case extension
          when 'csv'
            self::CSV.parse file
          when 'json'
            self::JSON.parse file
          when 'xml'
            self::XML.parse file
        end

      if data[:header]
        data[:header].map! { |el| el.underscore.gsub(/\s+/, '_') }
      end

      attributes = resource.attribute_names
      attr_accessible = resource.attr_accessible[:default]
      restricted_attributes = ['id', 'created_at', 'updated_at']

      data[:data].each_with_index do |line, line_index|
        row = {}

        line.each_with_index do |value, cell_index|
          attribute = data[:header][cell_index]

          if attribute.in?(restricted_attributes) || !attribute.in?(attributes) || !attribute.in?(attr_accessible)
            next
          end

          row[attribute] = value
        end

        new_resource = resource.new(row)
        if new_resource.valid? && new_resource.save
          result[:imported] += 1
        elsif !new_resource.errors.messages.blank?
          result[:failed] += 1
          new_resource.errors.messages.each do |k,v|
            v.each do |em|
              result[:errors] << em
            end
          end
        end
      end

      result
    end

  end
end
