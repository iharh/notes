public aspect Tracing {

	private pointcut mainMethod () :
		execution(public static void main(String[]));

	before () : mainMethod() {
		System.out.println("> " + thisJoinPoint);
	}

	after () : mainMethod() {
		System.out.println("< " + thisJoinPoint);
	}

	private pointcut getMessageMethod () :
		execution(public String getMessage());

	before () : getMessageMethod() {
		System.out.println(">> " + thisJoinPoint);

		HelloWorld helloWorld = (HelloWorld)thisJoinPoint.getThis();
		System.out.println(">> otherMessage: " + helloWorld.getOtherMessage());
	}
}
