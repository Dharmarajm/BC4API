class ApplicationController < ActionController::API
	 before_action :authenticate_request 
     attr_reader :current_user
     

     # for accessing the methods written in the concern named exception_handler.rb
     include ExceptionHandler



     private
     def authenticate_request
       @current_user = AuthorizeApiRequest.call(request.headers).result
       render json: { error: 'Not Authorized' }, status: 401 unless @current_user
     end


end

