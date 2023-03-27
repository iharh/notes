D:\dev\Repo\springsource\spring-batch\trunk\spring-batch-core\src\main\java\org\springframework\batch\core\partition\support\
TaskExecutorPartitionHandler.java
SimpleStepExecutionSplitter.java
SimplePartitioner.java




JobInstance

JobParameters

JobExecution


StepExecution    - A StepExecution represents a single attempt to execute a Step.

ExecutionContext - Map of parameters/states for the step, which contains any data a developer needs persisted
                   across batch runs, such as statistics or state information needed to restart

2.0 Changes:
- Chunk-oriented processing (read N items, then write them as a chunk)
ItemReader, <ItemProcessor>, ItemWriter
??? ItemStream

/**
 * Strategy interface for providing the data. <br/>
 * 
 * Implementations are expected to be stateful and will be called multiple times
 * for each batch, with each call to {@link #read()} returning a different value
 * and finally returning <code>null</code> when all input data is
 * exhausted.<br/>
 * 
 * Implementations need *not* be thread safe and clients of a {@link ItemReader}
 * need to be aware that this is the case.<br/>
 * 
 * A richer interface (e.g. with a look ahead or peek) is not feasible because
 * we need to support transactions in an asynchronous batch.
 */
public interface ItemReader<T> {

	/**
	 * Reads a piece of input data and advance to the next one. Implementations
	 * <strong>must</strong> return <code>null</code> at the end of the input
	 * data set. In a transactional setting, caller might get the same item
	 * twice from successive calls (or otherwise), if the first call was in a
	 * transaction that rolled back.
	 * 
	 * @throws Exception if an underlying resource is unavailable.
	 */
	T read() throws Exception, UnexpectedInputException, ParseException;

}



/**
 * <p>
 * Marker interface defining a contract for periodically storing state and restoring from that state should an error
 * occur.
 * <p>
 */
public interface ItemStream {

	/**
	 * Open the stream for the provided {@link ExecutionContext}.
	 * 
	 * @throws IllegalArgumentException if context is null
	 */
	void open(ExecutionContext executionContext) throws ItemStreamException;

	/**
	 * Indicates that the execution context provided during open is about to be saved. If any state is remaining, but
	 * has not been put in the context, it should be added here.
	 * 
	 * @param executionContext to be updated
	 * @throws IllegalArgumentException if executionContext is null.
	 */
	void update(ExecutionContext executionContext) throws ItemStreamException;

	/**
	 * If any resources are needed for the stream to operate they need to be destroyed here. Once this method has been
	 * called all other methods (except open) may throw an exception.
	 */
	void close() throws ItemStreamException;
}



-----
StepExecutionSplitter
PartitionHandler
-----

--------------------------------------------------------------------------------------

PartitionStep (org.springframework.batch.core.partition.support) extends AbstractStep
??? don't have item reader/writer
{
...
	@Override
	protected void doExecute(StepExecution stepExecution) throws Exception {

		// Wait for task completion and then aggregate the results
		Collection<StepExecution> executions = partitionHandler.handle(stepExecutionSplitter, stepExecution);
		stepExecution.upgradeStatus(BatchStatus.COMPLETED);
		stepExecutionAggregator.aggregate(stepExecution, executions);

		// If anything failed or had a problem we need to crap out
		if (stepExecution.getStatus().isUnsuccessful()) {
			throw new JobExecutionException("Partition handler returned an unsuccessful step");
		}

	}
...
}


/**
 * A {@link Step} implementation that provides common behavior to subclasses,
 * including registering and calling listeners.
 */
public abstract class AbstractStep implements Step, InitializingBean, BeanNameAware {
	private static final Log logger = LogFactory.getLog(AbstractStep.class);

	private String name;

	private int startLimit = Integer.MAX_VALUE;

	private boolean allowStartIfComplete = false;

	private CompositeStepExecutionListener stepExecutionListener = new CompositeStepExecutionListener();

	private JobRepository jobRepository;

	public void afterPropertiesSet() throws Exception {
		Assert.notNull(jobRepository, "JobRepository is mandatory");
	}

	/**
	 * Extension point for subclasses to execute business logic. Subclasses
	 * should set the {@link ExitStatus} on the {@link StepExecution} before
	 * returning.
	 * 
	 * @param stepExecution the current step context
	 * @throws Exception
	 */
	protected abstract void doExecute(StepExecution stepExecution) throws Exception;

	/**
	 * Extension point for subclasses to provide callbacks to their
	 * collaborators at the beginning of a step, to open or acquire resources.
	 * Does nothing by default.
	 * 
	 * @param ctx the {@link ExecutionContext} to use
	 * @throws Exception
	 */
	protected void open(ExecutionContext ctx) throws Exception {
	}

	/**
	 * Extension point for subclasses to provide callbacks to their
	 * collaborators at the end of a step (right at the end of the finally
	 * block), to close or release resources. Does nothing by default.
	 * 
	 * @param ctx the {@link ExecutionContext} to use
	 * @throws Exception
	 */
	protected void close(ExecutionContext ctx) throws Exception {
	}

	/**
	 * Template method for step execution logic - calls abstract methods for
	 * resource initialization ({@link #open(ExecutionContext)}), execution
	 * logic ({@link #doExecute(StepExecution)}) and resource closing (
	 * {@link #close(ExecutionContext)}).
	 */
	public final void execute(StepExecution stepExecution) throws JobInterruptedException,
			UnexpectedJobExecutionException {
		
		logger.debug("Executing: id="+stepExecution.getId());
		stepExecution.setStartTime(new Date());
		stepExecution.setStatus(BatchStatus.STARTED);
		getJobRepository().update(stepExecution);

		// Start with a default value that will be trumped by anything
		ExitStatus exitStatus = ExitStatus.EXECUTING;
		Exception commitException = null;

		StepSynchronizationManager.register(stepExecution);

		try {
			getCompositeListener().beforeStep(stepExecution);
			open(stepExecution.getExecutionContext());

			try {
				doExecute(stepExecution);
			}
			catch (RepeatException e) {
				throw e.getCause();
			}
			exitStatus = ExitStatus.COMPLETED.and(stepExecution.getExitStatus());

			// Check if someone is trying to stop us
			if (stepExecution.isTerminateOnly()) {
				throw new JobInterruptedException("JobExecution interrupted.");
			}

			// Need to upgrade here not set, in case the execution was stopped
			stepExecution.upgradeStatus(BatchStatus.COMPLETED);
			logger.debug("Step execution success: id=" + stepExecution.getId());
		}
		catch (Throwable e) {
			logger.error("Encountered an error executing the step", e);
			stepExecution.upgradeStatus(determineBatchStatus(e));
			exitStatus = exitStatus.and(getDefaultExitStatusForFailure(e));
			stepExecution.addFailureException(e);
		}
		finally {

			try {
				// Update the step execution to the latest known value so the listeners can act on it
				exitStatus = exitStatus.and(stepExecution.getExitStatus());
				stepExecution.setExitStatus(exitStatus);
				exitStatus = exitStatus.and(getCompositeListener().afterStep(stepExecution));
			}
			catch (Exception e) {
				logger.error("Exception in afterStep callback", e);
			}

			try {
				getJobRepository().updateExecutionContext(stepExecution);
			}
			catch (Exception e) {
				stepExecution.setStatus(BatchStatus.UNKNOWN);
				exitStatus = exitStatus.and(ExitStatus.UNKNOWN);
				stepExecution.addFailureException(e);
				logger.error("Encountered an error saving batch meta data."
						+ "This job is now in an unknown state and should not be restarted.", commitException);
			}

			stepExecution.setEndTime(new Date());
			stepExecution.setExitStatus(exitStatus);

			try {
				getJobRepository().update(stepExecution);
			}
			catch (Exception e) {
				stepExecution.setStatus(BatchStatus.UNKNOWN);
				stepExecution.setExitStatus(exitStatus.and(ExitStatus.UNKNOWN));
				stepExecution.addFailureException(e);
				logger.error("Encountered an error saving batch meta data."
						+ "This job is now in an unknown state and should not be restarted.", commitException);
			}

			try {
				close(stepExecution.getExecutionContext());
			}
			catch (Exception e) {
				logger.error("Exception while closing step execution resources", e);
				stepExecution.addFailureException(e);
			}

			StepSynchronizationManager.release();

			logger.debug("Step execution complete: " + stepExecution.getSummary());
		}
	}

	/**
	 * Determine the step status based on the exception.
	 */
	private static BatchStatus determineBatchStatus(Throwable e) {
		if (e instanceof JobInterruptedException || e.getCause() instanceof JobInterruptedException) {
			return BatchStatus.STOPPED;
		}
		else {
			return BatchStatus.FAILED;
		}
	}

	/**
	 * Default mapping from throwable to {@link ExitStatus}. Clients can modify
	 * the exit code using a {@link StepExecutionListener}.
	 * 
	 * @param ex the cause of the failure
	 * @return an {@link ExitStatus}
	 */
	private ExitStatus getDefaultExitStatusForFailure(Throwable ex) {
		ExitStatus exitStatus;
		if (ex instanceof JobInterruptedException || ex.getCause() instanceof JobInterruptedException) {
			exitStatus = ExitStatus.STOPPED.addExitDescription(JobInterruptedException.class.getName());
		}
		else if (ex instanceof NoSuchJobException || ex.getCause() instanceof NoSuchJobException) {
			exitStatus = new ExitStatus(ExitCodeMapper.NO_SUCH_JOB, ex.getClass().getName());
		}
		else {
			exitStatus = ExitStatus.FAILED.addExitDescription(ex);
		}

		return exitStatus;
	}
}


/**
 * Batch domain interface representing the configuration of a step. As with the {@link Job}, a {@link Step} is meant to
 * explicitly represent a the configuration of a step by a developer, but also the ability to execute the step.
 */
public interface Step {
	// @return the name of this step.
	String getName();

	// @return true if a step that is already marked as complete can be started again.
	boolean isAllowStartIfComplete();

	// @return the number of times a job can be started with the same identifier.
	int getStartLimit();

	/**
	 * Process the step and assign progress and status meta information to the {@link StepExecution} provided. The
	 * {@link Step} is responsible for setting the meta information and also saving it if required by the
	 * implementation.<br/>
	 * 
	 * It is not safe to re-use an instance of {@link Step} to process multiple concurrent executions.
	 * 
	 * @param stepExecution an entity representing the step to be executed
	 * 
	 * @throws JobInterruptedException if the step is interrupted externally
	 */
	void execute(StepExecution stepExecution) throws JobInterruptedException;
}



ColumnRangePartitioner - partition based on column ranges





















ProActive:

ProActiveMaster

ProActiveSchedulerPartitionHandler implements PartitionHandler


