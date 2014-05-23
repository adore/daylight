##
# Mixin helpers to get specific params in an +ActionController+
module Daylight::Helpers
  def scoped_params
    params[:scopes]
  end

  def filter_params
    params[:filters]
  end

  def order_params
    params[:order] if params[:order].present?
  end

  def limit_params
    params[:limit] if params[:limit].present?
  end

  def offset_params
    # non-integer offsets are allowed by offset, we do the check for you
    Integer(params[:offset]) if params[:offset].present?
  end

  def associated_params
    params[:associated]
  end

  def remoted_params
    params[:remoted]
  end
end
