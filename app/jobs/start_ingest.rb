class StartIngest
  @queue = :ingest_queue

  def self.perform(client_id)
    Client.run(client_id)
  end
end
