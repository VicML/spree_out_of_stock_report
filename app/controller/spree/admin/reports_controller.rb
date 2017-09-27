#Controller for Out of Stock Report

#For controller use : https://gist.github.com/wrburgess/4676144#file-reports_controller-rb-L10
#For View use       : https://github.com/spree/spree/blob/master/backend/app/views/spree/admin/reports/sales_total.html.erb

module Spree
  module Admin
    class ReportsController < Spree::Admin::BaseController

      respond_to :html

      AVAILABLE_REPORTS = {
        
        :sales_total => { :name => "Sales Total", :description => "Sales Total" },
        :out_of_stock => { :name => I18n.t(:out_of_stock), :description => I18n.t(:out_of_stock_description) }
      }
      
      def index
        @reports = AVAILABLE_REPORTS
        respond_with(@reports)
      end

      def sales_total
        params[:q] = {} unless params[:q]

        if params[:q][:created_at_gt].blank?
          params[:q][:created_at_gt] = Time.zone.now.beginning_of_month
        else
          params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
        end

        if params[:q] && !params[:q][:created_at_lt].blank?
          params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
        end

        if params[:q].delete(:completed_at_not_null) == "1"
          params[:q][:completed_at_not_null] = true
        else
          params[:q][:completed_at_not_null] = false
        end

        params[:q][:s] ||= "created_at desc"

        @search = Order.complete.ransack(params[:q])
        @orders = @search.result

        @totals = {}
        @orders.each do |order|
          @totals[order.currency] = { :item_total => ::Money.new(0, order.currency), :adjustment_total => ::Money.new(0, order.currency), :sales_total => ::Money.new(0, order.currency) } unless @totals[order.currency]
          @totals[order.currency][:item_total] += order.display_item_total.money
          @totals[order.currency][:adjustment_total] += order.display_adjustment_total.money
          @totals[order.currency][:sales_total] += order.display_total.money
        end
      end

      #To Know Out of Stock see: https://guides.spreecommerce.org/developer/inventory.html
      #We Need To Know when on_hand is 0
      
      def out_of_stock
      params[:q] = {} unless params[:q]

        if params[:created_at_gt].blank?
          params[:created_at_gt] = Time.zone.now.beginning_of_month
        else
          params[:created_at_gt] = Time.zone.parse(params[:created_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
        end

        if !params[:created_at_lt].blank?
          params[:created_at_lt] = Time.zone.parse(params[:created_at_lt]).end_of_day rescue ""
        end
        

        @products = Spree::Product.joins("LEFT JOIN spree_stock_items on spree_stock_items.variant_id = spree_products.id").
          where(spree_stock_items: {count_on_hand: 0}).
          where("spree_stock_items.created_at >= ? and spree_stock_items.created_at <= ?",params[:created_at_gt],params[:created_at_lt] ).
          order("spree_stock_items.created_at")
        
        
      end

    end
  end
end