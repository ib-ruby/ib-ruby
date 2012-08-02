class AddIbBars < ActiveRecord::Migration

  def change
    # This is a single data point delivered by HistoricData or RealTimeBar messages.
    create_table(:ib_bars) do |t|
      t.references :contract
      t.float :open #       double:
      t.float :high #       double:
      t.float :low #        double:
      t.float :close #      double:
      t.float :wap #      double:
      t.integer :volume #
      t.integer :trades # Number of trades during the time period the bar covers
      t.boolean :has_gaps, :limit => 1 # Whether or not there are gaps in the data
      t.string :time, :limit => 18 # String! The order execution time
      t.timestamps
    end
  end
end

__END__
rails generate scaffold bar contract_id:integer open:float high:float low:float close:float
 wap:float volume:integer trades:integer has_gaps:boolean time:string 

