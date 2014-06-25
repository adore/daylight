class API::V1::CompaniesController < APIController
  handles :index, :show, :associated

  private
    def company_params
      params.require(:company).permit(:name)
    end
end
