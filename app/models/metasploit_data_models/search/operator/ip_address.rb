# Operator for `inet` columns in a PostgreSQL database, which operates on formatted values using
# {MetasploitDataModels::Search::Operation::IPAddress}.
class MetasploitDataModels::Search::Operator::IPAddress < Metasploit::Model::Search::Operator::Single
  #
  # Attributes
  #

  # @!attribute [r] attribute
  #   The attribute on `Metasploit::Model::Search::Operator::Base#klass` that is searchable.
  #
  #   @return [Symbol] the attribute name
  attr_accessor :attribute

  #
  # Validations
  #

  validates :attribute,
            presence: true

  #
  # Instance Methods
  #

  alias_method :name, :attribute

  # The class used for `#operte_on`.
  #
  # @return [String] `'MetasploitDataModels::Search::Operation::IPAddress'`
  def operation_class_name
    @operation_class_name ||= 'MetasploitDataModels::Search::Operation::IPAddress'
  end

  # @return [Symbol] `:ip_address`
  def type
    :ip_address
  end
end