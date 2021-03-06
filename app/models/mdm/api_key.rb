class Mdm::ApiKey < ActiveRecord::Base
  #
  # Validators
  #

  validate :supports_api
  validates :token, :presence => true, :length => { :minimum => 8 }

  protected

  def supports_api
    license = License.get

    if license and not license.supports_api?
      errors[:license] = " - this product does not support API access"
    end
  end

  Metasploit::Concern.run(self)
end
