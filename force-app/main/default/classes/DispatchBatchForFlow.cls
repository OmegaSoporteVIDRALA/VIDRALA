public class DispatchBatchForFlow {
    
    @InvocableMethod(label='Run DispatchLoadBatch' description='Run DispatchLoadBatch')
    public static void runBatch() {
        DispatchLoadBatch dlb = new DispatchLoadBatch();

		ID jobId = Database.executeBatch(dlb);
    }
}