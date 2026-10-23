abstract class UseCase<T, Params> {
  T call(Params request);
}
